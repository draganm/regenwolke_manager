When(/^new deployment has been posted$/) do
  RegenwolkeAutons::RegenwolkeAuton.any_instance.should_receive(:deploy_application).with('app1', 'some_sha')
  post '/new_deployment', {application: 'app1', git_sha1: 'some_sha'}.to_json,  "CONTENT_TYPE" => "application/json"
end

Then(/^regenwolke auton should have deploy_application step scheduled$/) do
  last_response.status.should be(202)
  last_response.body.should be_empty
end
