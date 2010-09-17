module EmailTestsHelper
  
  def setup
    super
    emails_catching_setup
  end
  
  def teardown
    super
    emails_catching_teardown
  end
  
  def emails_catching_setup
    @@delivered_mail = []
    ActionMailer::Base.class_eval do
      alias deliver_original deliver!
      def deliver!(mail = @mail)
        @@delivered_mail << mail
      end
    end
  end
  
  def emails_catching_teardown
    ActionMailer::Base.class_eval do
      alias deliver! deliver_original
    end    
  end
  
  def assert_nothing_mailed(add_to_err_string = "")
    if add_to_err_string.size > 0
      add_to_err_string += ". "
    end
    assert @@delivered_mail.empty?, "#{add_to_err_string}Expected to have NOT mailed out a notification, but mailed: \n#{@@delivered_mail}"
  end
  
  def assert_error_mail_contains(text)
    assert(mailed_error.index(text), 
      "Expected mailed error body to contain '#{text}', but not found. \n actual contents: \n#{mailed_error}")    
  end
  
  def mailed_error
    assert @@delivered_mail.last, "Expected to have mailed out a notification about an error occuring, but none mailed"
    @@delivered_mail.last.encoded
  end
  
  def assert_mail_contains(text)
    assert((last_email.index(text) || last_email.gsub("=\n", "").index(text)) , 
      "Expected mailed email body to contain '#{text}', but not found. \n actual contents: \n#{last_email}")    
  end
  
  def assert_mail_does_not_contain(text)
    assert(!last_email.index(text), 
      "Expected mailed email body NOT to contain '#{text}', but found. \n actual contents: \n#{last_email}")    
  end
    
  def last_email
     assert @@delivered_mail.last, "Expected to have mailed out an email of some sort, but none mailed"
     @@delivered_mail.last.encoded     
  end
  
  def delivered_mail
    @@delivered_mail.collect{ |dm| dm.encoded }
  end
  
  def delivered_emails_to
    delivered_mail.collect{ |dm| dm.match(/To: (.*)\r\n/)[1] }
  end
  
end