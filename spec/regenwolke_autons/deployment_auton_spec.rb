module RegenwolkeAutons

  describe DeploymentAuton do

    let (:context) {spy :context}

    before do
      subject.context = context
    end


    describe '#terminate' do
      let (:context) {double :context}
      before do
        subject.host_ip = '1.2.3.4'
        subject.container_id = 'some_container_id'
      end

      let (:docker_container) {double :docker_container}

      it "should delete container and release port to port manager" do
        expect(Docker::Container).to receive(:get).with('some_container_id').and_return(docker_container)
        expect(docker_container).to receive(:delete).with(force: true)
        expect(context).to receive(:terminate)
        subject.terminate
      end
    end

    describe '#start' do

      before do
        subject.start 'app1', 'some_sha'
      end

      it 'should store application name' do
        expect(subject.application_name).to eq('app1')
      end

      it 'should store git_sha1 and schedule :start_container' do
        expect(subject.git_sha1).to eq('some_sha')
      end

    end


    describe '#start_container' do

      let(:docker_container) {spy :docker_container}

      before do
        allow(Docker::Container).to receive(:create).and_return(docker_container)
        allow(docker_container).to receive(:id).and_return('docker_id')
        subject.start_container
      end

      it 'should start container' do
        expect(Docker::Container).to have_received(:create)
        expect(docker_container).to have_received(:start)
      end

      it 'should schedule :notify_application' do
        expect(context).to have_received(:schedule_step).with(:wait_for_container_to_start)
      end

      it 'should store container id' do
        expect(subject.container_id).to eq('docker_id')
      end

    end

    describe '#wait_for_container_to_start' do
      context 'when the application is not running' do
        before do
          expect(subject).to receive(:endpoint_responding?).and_return(false)
        end
        it 'should re-schedule self execution in 3 seconds and increase number of retries' do
          expect(context).to receive(:schedule_delayed_step).with(3,:wait_for_container_to_start, [1])
          subject.wait_for_container_to_start
        end
      end

      context 'when the application is not running' do
        before do
          expect(subject).to receive(:endpoint_responding?).and_return(true)
        end
        it 'should re-schedule self execution in 3 seconds and increase number of retries' do
          expect(context).to receive(:schedule_step).with(:notify_application)
          subject.wait_for_container_to_start
        end
      end

      context 'when the number of retries is > 10' do
        it 'should raise an exception' do
          expect{subject.wait_for_container_to_start(10)}.to raise_error
        end
      end

    end

    describe '#notify_application' do

      it "should schedule :deployment_complete step with sha1 of the deployment and port number on the application auton and schedule repeating of container check" do
        subject.application_name = 'some_app'
        subject.git_sha1 = 'some_sha1'
        subject.host_ip = '1.2.3.4'
        context = double :context
        subject.context = context

        expect(context).to receive(:schedule_step_on_auton).with("application:some_app", :deployment_complete, ['some_sha1', '1.2.3.4', 5000])
        expect(context).to receive(:schedule_delayed_step).with(30 , :check_container)


        subject.notify_application

      end
    end

    describe '#check_container' do
      let (:container) {double :container}

      context "when the container is running" do
        before do
          subject.container_id = 'some_id'
          expect(Docker::Container).to receive(:get).with('some_id').and_return(container)
          expect(container).to receive(:json).and_return({'State' => {'Running' => true}})
        end
        it "should schedule next check in 60 seconds" do
          expect(context).to receive(:schedule_delayed_step).with(60,:check_container)
          subject.check_container
        end
      end

      context "when the container is not running" do
        before do
          subject.container_id = 'some_id'
          expect(Docker::Container).to receive(:get).with('some_id').and_return(container)
          expect(container).to receive(:json).and_return({'State' => {'Running' => false}})
        end
        it "should delete the container, schedule #start_container and set container_id not nil" do
          expect(container).to receive(:delete).with(force: true)
          expect(context).to receive(:schedule_step).with(:start_container)
          subject.check_container
          expect(subject.container_id).to be_nil
        end
      end
    end

  end


end
