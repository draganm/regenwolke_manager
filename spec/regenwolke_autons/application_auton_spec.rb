module RegenwolkeAutons

  describe ApplicationAuton do

    let (:context) {double :context}

    before do
      subject.context = context
      subject.application_name = 'app1'
    end


    describe '#start' do
      before do
        subject.start 'app1'
      end

      it 'should store application_name' do
        expect(subject.application_name).to eq('app1')
      end

      it 'should store host_matcher' do
        expect(subject.host_matcher).to eq('app1\..+')
      end

      context 'when application_name is a fqdn' do
        it 'should store host_matcher matching exactly the fqdn' do
          subject.start('some.domain.com')
          expect(subject.host_matcher).to eq('some\.domain\.com')
        end
      end

      context 'when application_name is a fqdn starting with www.' do
        it 'should store host_matcher matching fqdn with and without www. prefix' do
          subject.start('www.domain.com')
          expect(subject.host_matcher).to eq('(www\.domain\.com)|(domain\.com)')
        end
      end

    end

    describe '#deploy' do

      it 'should start a new deployment process' do
        expect(context).to receive(:create_auton).with('RegenwolkeAutons::DeploymentAuton', 'deployment:app1:some_sha')
        expect(context).to receive(:schedule_step_on_auton).with('deployment:app1:some_sha', :start, ['app1','some_sha'])
        subject.deploy('some_sha')

      end

    end

    describe '#deployment_complete' do

      before do
        subject.host_matcher='app1\..+'
        ENV['LOCAL_IP']='2.4.5.6'
      end

      context 'when there is not running deployment' do
        it 'should change endpoints on nginx' do

          expect(context).to receive(:schedule_step_on_auton).with("nginx", :update_application_configuration, ["app1", {"host_matcher"=>"app1\\..+", "endpoints"=>[{"hostname"=>"1.2.3.4", "port"=>123}]}])

          subject.deployment_complete('some_sha','1.2.3.4', 123)
        end
      end


      context 'when there is already a running deployment' do

        context 'when the running deployment is different from this one' do
          before do
            subject.current_deployment = CurrentDeployment.from_structure({
              'git_sha1' => 'old_sha',
              'host_ip' => '1.2.3.4',
              'port' => 333
            })
          end
          it 'should change endpoints on nginx and terminate existing deployment' do

            expect(context).to receive(:schedule_step_on_auton).with("nginx", :update_application_configuration, ["app1", {"host_matcher"=>"app1\\..+", "endpoints"=>[{"hostname"=>"1.2.3.4", "port"=>123}]}])
            expect(context).to receive(:schedule_step_on_auton).with("deployment:app1:old_sha", :terminate)

            subject.deployment_complete('some_sha','1.2.3.4',123)
            expect(subject.current_deployment.git_sha1).to eq('some_sha')
            expect(subject.current_deployment.host_ip).to eq('1.2.3.4')
            expect(subject.current_deployment.port).to eq(123)
          end
        end

        context 'when the running deployment is not different from this one' do
          before do
            subject.current_deployment = CurrentDeployment.from_structure({
              'git_sha1' => 'some_sha',
              'host_ip' => '8.2.3.4',
              'port' => 333
            })
          end

          it 'should change endpoints on nginx and not terminate existing deployment' do

            expect(context).to receive(:schedule_step_on_auton).with("nginx", :update_application_configuration, ["app1", {"host_matcher"=>"app1\\..+", "endpoints"=>[{"hostname"=>"1.2.3.4", "port"=>123}]}])
            expect(context).to_not receive(:schedule_step_on_auton).with("deployment:app1:some_sha", :terminate)

            subject.deployment_complete('some_sha','1.2.3.4',123)
            expect(subject.current_deployment.git_sha1).to eq('some_sha')
            expect(subject.current_deployment.host_ip).to eq('1.2.3.4')
            expect(subject.current_deployment.port).to eq(123)
          end
        end

      end

    end

  end
end
