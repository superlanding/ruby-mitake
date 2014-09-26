## 三竹簡訊 API (尚未整理)


### initializer/mitake.rb

```ruby
Mitake::API.username = Setting.username
Mitake::API.password = Setting.password
Mitake::API.logger = true # or false (忘記是什麼)
```


### Usage

```ruby
# 取得目前點數
Mitake::API.fetch_credit! 
```


```ruby
# Define a SMS template 
# app/sms/user_sms
class UserSms < Mitake::Base
  define_message :welcome, "Hello, {nickname}, you are welcome"
  define_message :change_password, "Hello, {nickname}, your password has been changed in {time}"
end


# Send a message
UserSms.send_welcome!('09xxxxxxxx', nickname: 'Eddie Li')
UserSms.send_change_password!('09xxxxxxxx', nickname: 'Eddie Li', time: '11:30 AM')
```