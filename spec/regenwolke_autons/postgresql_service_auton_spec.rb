module RegenwolkeAutons

  describe PostgresqlServiceAuton do

    let (:context) {spy :context}

    before do
      subject.context = context
    end

    describe '#start' do
      let (:context) {double :context}
      it 'does nothing' do
        subject.start
      end
    end

    describe '#create_instance' do

      context 'when the instance does not exist' do

        before do
          subject.create_instance 'instancename'
        end

        it 'should create new PostgresqlServiceInstance' do
          expect(context).to have_received(:create_auton).with("RegenwolkeAutons::PostgresqlInstanceAuton", "postgresql:instancename")
        end

        it 'should store the service name and instance name' do
          expect(subject.instances).to eq({"instancename"=>"postgresql:instancename"})
        end

        it 'should schedule start on the service instance auton' do
          expect(context).to have_received(:schedule_step_on_auton).with('postgresql:instancename', :start, ["instancename"])
        end

      end


      context 'when the instance already exists' do
        let (:context) {double :context}
        before do
          subject.instances = {"instancename"=>"postgresql:instancename"}
        end
        it 'should not do anything' do
          subject.create_instance 'instancename'
        end
      end

      describe '#add_instance_to_application' do
        context 'when instance exists' do

          before do
            subject.instances = {"instancename"=>"postgresql:instancename"}
          end

          it 'should schedule add_instance_to_application with same parameters on the instance' do
            subject.add_instance_to_application 'instancename', 'app1', true
            expect(context).to have_received(:schedule_step_on_auton).with('postgresql:instancename', :add_instance_to_application, ['app1', true])
          end
        end
      end

    end

  end
end
