module RegenwolkeAutons

  describe PostgresqlInstanceAuton do

    let (:context) {spy :context}

    before do
      subject.context = context
    end

    describe '#start' do
      before do
        subject.start 'somename'
      end
      it 'should set instance name' do
        expect(subject.instance_name).to eq('somename')
      end
      it 'should schedule #generate_credentials' do
        expect(context).to have_received(:schedule_step).with(:generate_credentials)
      end
      it 'should schedule #generate_credentials' do
        expect(context).to have_received(:schedule_step).with(:generate_credentials)
      end
      it 'should schedule #start_container' do
        expect(context).to have_received(:schedule_step).with(:start_container)
      end
      it 'schould set applications to empty array' do
        expect(subject.applications).to eq([])
      end
    end

    describe 'generate_credentials' do
      before do
        subject.generate_credentials
      end
      it 'should set username with length 16' do
        expect(subject.username.length).to be(16)
      end
      it 'should set password with length 24' do
        expect(subject.password.length).to be(24)
      end
    end

    describe '#start_container' do
      let(:container) {double :container}

      it 'should start docker container' do
        subject.username = 'username'
        subject.password = 'password'
        expect(Docker::Container).to receive(:create).with(
        'Image' => 'postgres:9.4.0',
        "Env" => [
          "POSTGRES_USER=username",
          "POSTGRES_PASSWORD=password"
        ]
        ).and_return(container)

        expect(container).to receive(:start)
        expect(container).to receive(:id).and_return('container_id')
        expect(container).to receive(:json).and_return({'NetworkSettings' => {'IPAddress' => '1.2.3.4'}})

        subject.start_container

        expect(subject.container_id).to eq('container_id')
        expect(subject.server_ip).to eq('1.2.3.4')
      end
    end

    describe '#add_instance_to_application' do
      before do
        subject.applications = []
        subject.instance_name = 'SOMENAME'
        subject.server_ip = '1.2.3.4'
        subject.username = 'user'
        subject.password = 'pass'
      end
      context 'when it is not the default database instance' do
        it 'should schedule set_environment on the application auton' do
          subject.add_instance_to_application 'app1', false
          expect(context).to have_received(:schedule_step_on_auton).with("application:app1", :set_environment, [{"SOMENAME_REGENWOLKE_POSTGRES_URL"=>"postgres://user:pass@1.2.3.4:5432/user"}])
        end
      end

      context 'when it is the default database instance' do
        it 'should schedule set_environment on the application auton and set DATABASE_URL' do
          subject.add_instance_to_application 'app1', true
          expect(context).to have_received(:schedule_step_on_auton).with("application:app1", :set_environment, [
            {"SOMENAME_REGENWOLKE_POSTGRES_URL"=>"postgres://user:pass@1.2.3.4:5432/user",
            "DATABASE_URL"=>"postgres://user:pass@1.2.3.4:5432/user"},
            ])
        end
      end
    end

  end
end
