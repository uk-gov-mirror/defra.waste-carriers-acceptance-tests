Given(/^I renew my registration using my previous registration number "([^"]*)"$/) do |reg|
  @front_app = FrontOfficeApp.new
  @front_app.start_page.load
  @front_app.start_page.submit(renewal: true)
  @front_app.existing_registration_page.submit(reg_no: reg)
end

Given(/^I choose to renew my registration using my previous registration number$/) do
  Capybara.reset_session!
  @front_app = FrontOfficeApp.new
  @front_app.start_page.load
  @front_app.start_page.submit(renewal: true)
  @front_app.existing_registration_page.submit(reg_no: @registration_number)
end

When(/^I complete the public body registration renewal$/) do
  @front_app.business_type_page.submit
  @front_app.other_businesses_question_page.submit(choice: :no)
  @front_app.construction_waste_question_page.submit(choice: :yes)
  @front_app.registration_type_page.submit
  @front_app.business_details_page.submit(
    postcode: "S60 1BY",
    result: "ENVIRONMENT AGENCY, BOW BRIDGE CLOSE, ROTHERHAM, S60 1BY"
  )
  @email = @front_app.generate_email
  @front_app.contact_details_page.submit(
    first_name: "Bob",
    last_name: "Carolgees",
    phone_number: "012345678",
    email: @email
  )
  @front_app.postal_address_page.submit

  people = @front_app.key_people_page.key_people

  @front_app.key_people_page.submit_key_person(person: people[0])
  @front_app.relevant_convictions_page.submit(choice: :no)
  @front_app.declaration_page.submit
  @front_app.sign_up_page.submit(
    registration_password: "Secret123",
    confirm_password: "Secret123",
    confirm_email: @email
  )
  @front_app.order_page.submit(
    copy_card_number: "2",
    choice: :card_payment
  )
  click(@front_app.worldpay_card_choice_page.maestro)

  # finds today's date and adds another year to expiry date
  time = Time.new

  @year = time.year + 1

  @front_app.worldpay_card_details_page.submit(
    card_number: "6759649826438453",
    security_code: "555",
    cardholder_name: "3d.authorised",
    expiry_month: "12",
    expiry_year: @year
  )
  @front_app.worldpay_card_details_page.submit_button.click
  # Stores registration number for later use
  @registration_number = @front_app.confirmation_page.registration_number.text
  @front_app.mailinator_page.load
  @front_app.mailinator_page.submit(inbox: @email)
  @front_app.mailinator_inbox_page.confirmation_email.click
  @front_app.mailinator_inbox_page.email_details do |frame|
    @new_window = window_opened_by { frame.confirm_email.click }
  end
end

Then(/^the expiry date should be three years from the expiry date$/) do
  # Adds three years to expiry date and then checks expiry date reported in registration details
  registration_expiry_date = Date.new(2018, 2, 5)

  @new_expiry_date = registration_expiry_date.next_year(3).strftime("%d/%m/%Y")
  @back_app.registrations_page.search(search_input: @registration_number)
  expect(@back_app.registrations_page.search_results[0].expiry_date.text).to eq(@new_expiry_date)
end

Then(/^I will be shown the renewal information page$/) do
  expect(@front_app.renewal_start_page).to have_text(@registration_number)
  expect(@front_app.renewal_start_page.current_url).to include "/renewal"
end

When(/^I choose to renew my registration from my registrations list$/) do
  @front_app.waste_carrier_registrations_page.user_registrations[0].renew_registration.click
end

Given(/^I choose to renew my registration$/) do
  Capybara.reset_session!
  @front_app = FrontOfficeApp.new
  @front_app.start_page.load
  @front_app.start_page.submit(renewal: true)
  @front_app.existing_registration_page.submit(reg_no: @registration_number)
end

When(/^I enter my lower tier registration number "([^"]*)"$/) do |reg_no|
  @front_app.existing_registration_page.submit(reg_no: reg_no)
end

Then(/^I'm informed "([^"]*)"$/) do |error_message|
  expect(@front_app.existing_registration_page.error_message.text).to eq(error_message)
end

When(/^the organisation type is changed to sole trader$/) do
  @front_app.renewal_start_page.submit
  @front_app.business_type_page.submit(org_type: "soleTrader")
end

Then(/^I'm informed I'll need to apply for a new registration$/) do
  expect(@front_app.type_change_page).to have_text("You cannot renew")
end

Then(/^I will have renewed my registration$/) do
  expect(@front_app.confirmation_page).to have_text("Renewal complete")
end

Then(/^a renewal confirmation email is received$/) do
  # resets session cookies to fix back office authentication issue
  Capybara.reset_session!
  @front_app = FrontOfficeApp.new
  @front_app.mailinator_page.load
  @front_app.mailinator_page.submit(inbox: @email)
  @front_app.mailinator_inbox_page.renewal_complete_email.click
  @front_app.mailinator_inbox_page.email_details do |_frame|
    expect(@front_app.confirmation_page).to have_text @registration_number
  end

end

Then(/^I will be informed my renewal is received$/) do
  expect(@front_app.renewal_received_page).to have_text("Renewal received")
  expect(@front_app.renewal_received_page).to have_text(@registration_number)
end

When(/^I change my registration type to "([^"]*)" and complete my renewal$/) do |registration_type|
  @front_app.renewal_start_page.submit
  @front_app.business_type_page.submit
  @front_app.other_businesses_question_page.submit(choice: :yes)
  @front_app.service_provided_question_page.submit(choice: :main_service)
  @front_app.only_deal_with_question_page.submit(choice: :not_farm_waste)
  @front_app.registration_type_page.submit(choice: registration_type.to_sym)
  @front_app.renewal_information_page.submit
  @front_app.company_name_page.submit
  @front_app.post_code_page.submit(postcode: "S60 1BY")
  @front_app.business_address_page.submit(
    result: "ENVIRONMENT AGENCY, BOW BRIDGE CLOSE, ROTHERHAM, S60 1BY"
  )
  @front_app.contact_details_page.submit
  @front_app.postal_address_page.submit

  people = @front_app.key_people_page.key_people
  @front_app.key_people_page.add_key_person(person: people[0])
  @front_app.key_people_page.add_key_person(person: people[1])
  @front_app.key_people_page.submit_key_person(person: people[2])

  @front_app.relevant_convictions_page.submit(choice: :no)
  @front_app.declaration_page.submit
end

Then(/^I'll be shown the "([^"]*)" renewal charge plus the "([^"]*)" charge for change$/) do |renewal, change|
  @actual_charge = "£" + @front_app.order_page.charge.value
  expect(@actual_charge).to eq(renewal)
  @renewal_charge = "£" + @front_app.order_page.edit_charge.value
  expect(@actual_charge).to eq(change)
end

When(/^I answer questions indicating I should be a lower tier waste carrier$/) do
  @front_app.renewal_start_page.submit
  @front_app.business_type_page.submit
  @front_app.other_businesses_question_page.submit(choice: :yes)
  @front_app.service_provided_question_page.submit(choice: :not_main_service)
  @front_app.construction_waste_question_page.submit(choice: :no)
  @front_app.registration_type_page.submit
end

Then(/^I will be informed I should not renew my upper tier waste carrier registration$/) do
  expect(@front_app.renewal_received_page).to have_text("You should not renew")
end

Given(/^I have signed in to renew my registration$/) do
  @front_app = FrontOfficeApp.new
  @front_app.waste_carriers_renewals_sign_in_page.load
  @front_app.waste_carrier_sign_in_page.submit(
    email: Quke::Quke.config.custom["accounts"]["waste_carrier"]["username"],
    password: Quke::Quke.config.custom["accounts"]["waste_carrier"]["password"]
  )
end

Given(/^I have chosen registration "([^"]*)" ready for renewal$/) do |_number|
  @front_app.waste_carriers_renewals_page.user_registrations[0].renew_registration.click
end

When(/^I complete my limited company renewal steps$/) do
  @front_app.renewal_start_page.submit
  @front_app.business_type_page.submit
  @front_app.other_businesses_question_page.submit
  @front_app.registration_type_page.submit
  @front_app.renewal_information_page.submit
  @front_app.limited_company_number_page.submit
  @front_app.company_name_page.submit_button.click
  @front_app.post_code_page.submit_button.click
  @front_app.business_address_page.submit_button.click
  @front_app.key_people_page.new_submit_button.click
  @front_app.relevant_convictions_page.submit
  @front_app.relevant_people_page.new_submit_button.click
  @front_app.contact_name_page.submit
  @front_app.contact_telephone_number_page.submit
  @front_app.contact_email_page.submit
  @front_app.contact_address_page.submit
  @front_app.check_details_page.submit_button.click
  @front_app.declaration_page.submit_button.click
  @front_app.order_page.submit_button_renew.click
  @front_app.worldpay_card_details_page.submit_button_renew.click
end

Then(/^I will be notified that my registration has been renewed$/) do
  expect(@front_app.confirmation_page).to have_text("Renewal complete")
end
