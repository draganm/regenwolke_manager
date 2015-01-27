module RegenwolkeAutons

  describe NginxAuton do

    def new_app_config(app_name, port=5000)
      ApplicationNginxConfiguration.from_structure({
        'host_matcher' => "#{app_name}\\..+",
        'endpoints' => [
          {
            'hostname' => '1.2.3.4',
            'port' => port
          }

        ]
      })
    end

    let(:context) {double :context}

    before do
      subject.context = context
    end

    describe '#start' do
      let (:context) {spy :context}
      before do
        subject.start
      end

      it 'should schedule :start_nginx_if_not_running step' do
        expect(context).to have_received(:schedule_step).with(:start_nginx_if_not_running)
      end

      it 'should schedule repetition of every 90 seconds after 90 seconds wait' do
        expect(context).to have_received(:schedule_repeating_delayed_step).with(90, 90, :start_nginx_if_not_running)
      end

      it 'should initialize configurations hash with regenwolke' do
        expect(subject.configurations.to_structure).to eq({"regenwolke"=>{"host_matcher"=>"regenwolke\\..+", "endpoints"=>[{"hostname"=>"localhost", "port"=>5000}]}})
      end

    end

    describe '#update_application_configuration' do

      let (:context) {spy :context}

      context 'when there are no existing endpoints' do
        it 'should add new endpoints' do
          subject.update_application_configuration('app1', new_app_config('app1'))
          expect(subject.configurations['app1'].to_structure).to eq(new_app_config('app1').to_structure)
        end
      end

      it 'should schedule :reconfigure_nginx step' do
        subject.update_application_configuration('app1', new_app_config('app1'))
        expect(context).to have_received(:schedule_step).with(:reconfigure_nginx)
      end

      context 'when there are existing endpoints' do
        before { subject.update_application_configuration('app1', new_app_config('app1')) }

        it 'should add the new endpoints' do
          subject.update_application_configuration('app2', new_app_config('app2'))
          expect(subject.configurations['app2'].to_structure).to eq(new_app_config('app2').to_structure)
          expect(subject.configurations['app1'].to_structure).to eq(new_app_config('app1').to_structure)
        end

        it 'should replace existing endpoints if required' do
          subject.update_application_configuration('app1', new_app_config('app3'))
          expect(subject.configurations['app1'].to_structure).to eq(new_app_config('app3').to_structure)
        end
      end

    end

    describe '#reconfigure_nginx' do

      it 'should create new nginx config, check config and reload config' do
        expect(subject).to receive(:create_and_save_config)
        expect(subject).to receive(:check_current_config)
        expect(subject).to receive(:reload_nginx_config)
        subject.reconfigure_nginx
      end

    end

    describe '#start_nginx' do
      it 'should create config, tests config, starts nginx and waits for nginx to start' do

        expect(subject).to receive(:create_and_save_config)
        expect(subject).to receive(:system).with('nginx','-t','-p', 'regenwolke/nginx', '-c', 'nginx.config').and_return(true)
        expect(subject).to receive(:system).with('nginx','-p', 'regenwolke/nginx', '-c', 'nginx.config').and_return(true)
        expect(subject).to receive(:wait_for_nginx)

        subject.start_nginx
      end

      context 'when config test fails' do
        it 'should raise exception' do
          expect(subject).to receive(:create_and_save_config)
          expect(subject).to receive(:system).with('nginx','-t','-p', 'regenwolke/nginx', '-c', 'nginx.config').and_return(false)
          expect {subject.start_nginx}.to raise_error('Invalid nginx config')
        end
      end

      context 'when nginx start fails' do
        it 'should raise exception' do
          expect(subject).to receive(:create_and_save_config)
          expect(subject).to receive(:system).with('nginx','-t','-p', 'regenwolke/nginx', '-c', 'nginx.config').and_return(true)
          expect(subject).to receive(:system).with('nginx','-p', 'regenwolke/nginx', '-c', 'nginx.config').and_return(false)
          expect {subject.start_nginx}.to raise_error('Could not start nginx')
        end
      end
    end

    describe '#start_nginx_if_not_running' do
      context 'when nginx is not running' do
        it 'should schedule :start_nginx' do
          expect(subject).to receive(:nginx_running?).and_return(false)
          expect(context).to receive(:schedule_step).with(:start_nginx)
          subject.start_nginx_if_not_running
        end
      end

      context 'when nginx is running' do
        it 'should not schedule :start_nginx' do
          expect(subject).to receive(:nginx_running?).and_return(true)
          expect(context).not_to receive(:schedule_step).with(:start_nginx)
          subject.start_nginx_if_not_running
        end
      end

    end

    describe '#wait_for_nginx' do
      context 'when nginx is running' do

        it 'should terminate immediately' do
          expect(subject).to receive(:nginx_running?).and_return(true)
          subject.send(:wait_for_nginx)
        end

      end

      context 'when nginx is not running immediately' do

        context 'when nginx is running on the second check' do

          it 'should sleep for 0.1 seconds and terminate' do
            expect(subject).to receive(:nginx_running?).and_return(false, true)
            expect(subject).to receive(:sleep).with(0.1)
            subject.send(:wait_for_nginx)
          end

        end

      end

      context 'when nginx is not running after 20 checks' do

        it 'should raise an error' do
          expect(subject).to receive(:nginx_running?).and_return(false).exactly(20).times
          expect(subject).to receive(:sleep).with(0.1).exactly(20).times
          expect{ subject.send(:wait_for_nginx) }.to raise_error("nginx didn't start within 20 seconds")
        end

      end

    end

    describe '#create_config' do

      context 'when there are no endpoints' do

        it 'should create config with only regenwolke host entry' do
          server_names = subject.send(:create_config).split("\n").map(&:strip!).select{ |l|  l =~ /^server .*:.*;$/}
          expect(server_names).to eq(["server localhost:5000;"])
        end

      end

      context 'when there are two app endpoints' do
        let (:context) {spy :context}
        before do
          subject.update_application_configuration('app1', new_app_config('app1',123))
          subject.update_application_configuration('app2', new_app_config('app2',124))

        end

        it 'should create config with all endpoins' do
          server_names = subject.send(:create_config).split("\n").map(&:strip!).select{ |l|  l =~ /^server .*:.*;$/}
          expect(server_names.sort).to eq([
            "server localhost:5000;",
            "server 1.2.3.4:123;",
            "server 1.2.3.4:124;"
          ].sort)
        end
      end
    end

  end
end