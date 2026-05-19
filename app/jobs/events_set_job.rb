class EventsSetJob < ApplicationJob
  queue_as :default

  def perform(*args)
    ## check for all events today that are due today and send email to customers
    events = Event.due_today

    puts "----- - - - - Found #{events.count} events due today. Sending emails to customers..." if events.any?

    events.find_each do |event|
      if event.customer&.email.present? and event.hora_inicio <= DateTime.current
        puts "----- - - - - Sending email for event #{event.id} to customer #{event.customer.email}"
        EventMailer.with(event: event, email: event.customer.email).send_event_today.deliver_later
      end
    end
  end
end
