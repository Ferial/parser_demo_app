module XmlParser

  class DatabaseWriter

    def initialize(parser_obj = {})
      @partner                              = parser_obj.partner
      @partner_is_new                       = @partner.new_record?
      @available_items                      = parser_obj.available_items
      @not_available_items_partner_item_ids = parser_obj.not_available_items_partner_item_ids
      @batch_size                           = parser_obj.batch_size
    end

    def save
      if items_data_to_save?
        start_time = Time.now
        ActiveRecord::Base.transaction do
          save_partner
          lock_items_table
          mark_not_available_items
          add_new_and_update_existing_items
        end
        puts "db sync took: #{Time.now - start_time} seconds!"
      else
        puts "Nothing to save!"
      end
    end

    private

    def save_partner
      @partner.save if @partner_is_new
    end

    def lock_items_table
      Item.connection.execute("LOCK TABLE items IN EXCLUSIVE MODE;")
    end

    # faster than def below
    def mark_not_available_items
      if !@partner_is_new && items_to_mark_as_not_available?
        items_values_for_sql = @not_available_items_partner_item_ids.map do |partner_item_id|
          "(#{partner_item_id})"
        end.join(",")

        query = <<-SQL
          CREATE TEMPORARY TABLE IF NOT EXISTS not_available_items_from_xml
          (
            partner_item_id integer
          ) ON COMMIT DROP;

          INSERT INTO not_available_items_from_xml
          (
            partner_item_id
          ) VALUES #{items_values_for_sql};

          UPDATE items
          SET    available_in_store = 'f', updated_at = '#{date_time_for_sql}'
          FROM   not_available_items_from_xml
          WHERE  items.partner_id = #{@partner.id}
          AND    items.partner_item_id = not_available_items_from_xml.partner_item_id;
        SQL

        Item.connection.execute(query)
      end
    end

    # def mark_not_available_items
    #   if !@partner_is_new && items_to_mark_as_not_available?
    #     @partner.items
    #             .where(partner_item_id: @not_available_items_partner_item_ids)
    #             .update_all(available_in_store: false)
    #   end
    # end

    def add_new_and_update_existing_items
      if available_items?
        if @batch_size
          while available_items?
            items_batch = @available_items.shift @batch_size
            Item.connection.execute build_upsert_query_sql(items_batch)
          end
        else
          Item.connection.execute build_upsert_query_sql
        end
      end
    end

    def items_data_to_save?
      available_items? || items_to_mark_as_not_available?
    end

    def available_items?
      @available_items.present?
    end

    def items_to_mark_as_not_available?
      @not_available_items_partner_item_ids.present?
    end

    def build_items_values_for_sql(items_batch = nil)
      items = items_batch ? items_batch : @available_items

      items.map do |item|
        "('#{item[:title]}', #{item[:partner_item_id]}, 't')"
      end.join(",")
    end

    def date_time_for_sql
      DateTime.now.utc
    end

    def build_upsert_query_sql(items_batch = nil)
      if items_batch
        items_values_for_sql = build_items_values_for_sql(items_batch)
      else
        items_values_for_sql = build_items_values_for_sql
      end
      <<-SQL
        CREATE TEMPORARY TABLE IF NOT EXISTS items_from_xml
        (
          title varchar,
          partner_item_id integer,
          available_in_store boolean
        ) ON COMMIT DROP;
        #{ "TRUNCATE items_from_xml;" if items_batch }
        INSERT INTO items_from_xml ( title,
                                     partner_item_id,
                                     available_in_store ) VALUES #{items_values_for_sql};

        UPDATE items
        SET    title = items_from_xml.title, updated_at = '#{date_time_for_sql}'
        FROM   items_from_xml
        WHERE  items.partner_id = #{@partner.id}
        AND    items.partner_item_id = items_from_xml.partner_item_id;

        INSERT INTO items ( title,
                            partner_id,
                            partner_item_id,
                            available_in_store,
                            created_at,
                            updated_at )
        SELECT items_from_xml.title,
               #{@partner.id},
               items_from_xml.partner_item_id,
               items_from_xml.available_in_store,
               '#{date_time_for_sql}',
               '#{date_time_for_sql}'
        FROM items_from_xml
        WHERE  NOT EXISTS (
           SELECT 1
           FROM   items
           WHERE  items.partner_id = #{@partner.id}
           AND    items.partner_item_id = items_from_xml.partner_item_id
        );
      SQL
    end

  end

end
