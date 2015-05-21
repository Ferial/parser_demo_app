# Instructions:

> parser code in **app/parsers/xml_parser**

### Install
```
$ git clone https://github.com/Ferial/parser_demo_app.git
$ cd parser_demo_app
$ bundle install
```
> edit 'database.yml' if necessary, start postgresql server

### Run tests
```
$ rake db:test:prepare
$ rspec
```
### Create demo database
```
$ rake demo:create_db
```
### Generate demo xml
> 100000 items (50000 not available in store)

```
$ rake "demo:generate_demo_xml_file_to_dir[/dir/to/place/xml/file/]"
```

### Start http server
> open new terminal window

```
$ cd /dir/to/place/xml/file/
$ python -m SimpleHTTPServer 8000
```

### Run parser
> back to application folder

```
$ rails console
```
```ruby
existing_partner_info = { xml_url: 'http://0.0.0.0:8000/items.xml', xml_type: "YaMarket" }
parser = XmlParser::Parser.init(existing_partner_info)
parser.parse

# to run with sidekiq
XmlParserWorker.perform_async(existing_partner_info)
```
### Expected results
> for existing partner

| Query                                            | before   | after    |
| ------------------------------------------------ | :------: | :------: |
| Partner.count                                    | 1        | 1        |
| Item.count                                       | 100000   | 120000   |
| Item.where(available_in_store: false).count      | 0        | 50000    |
| Item.where(title: "item_to_update_title").count  | 0        | 30000    |
| Item.where(title: "new_item_title").count        | 0        | 20000    |

> for new partner

| Query         | before          | after    |
| --------------| :-------------: | :------: |
| Partner.count | 1               | 2        |
| Item.count    | 100000          | 150000   |

###Performance (2_500_000 records in db)
> OS X 10.8.5 (MacBook Pro 2014), Rails 4.2.1 (ruby 2.2.2), Postgresql 9.4.1

**execution_time:** 10.5 - 12.7 sec, **where db sync took** 3.3 - 5.5 sec (including time to build SQL)
