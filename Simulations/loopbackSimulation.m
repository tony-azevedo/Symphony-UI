% A simple loopback simulation for the SimulationDAQController. Returns all stimuli as responses (a loopback) or 
% simulates noise if no stimuli is defined for a particular channel.

function input = loopbackSimulation(daqController, output, timeStep)
    import Symphony.Core.*;

    input = NET.createGeneric('System.Collections.Generic.Dictionary', {'IDAQInputStream', 'IInputData'});

    inStreamEnum = daqController.ActiveInputStreams.GetEnumerator();

    while inStreamEnum.MoveNext()
        inStream = inStreamEnum.Current;
        inData = [];

        outStreamEnum = output.Keys.GetEnumerator();

        % Find the corresponding output data and make it into input data.
        while outStreamEnum.MoveNext()
            outStream = outStreamEnum.Current;

            if strcmp(outStream.Name, strrep(inStream.Name, '_IN.', '_OUT.'))
                outData = output.Item(outStream);
                inData = InputData(outData.Data, outData.SampleRate, daqController.Clock.Now);
                break;
            end
        end

        % If there was no corresponding output, simulate noise.
        if isempty(inData)
            samples = Symphony.Core.TimeSpanExtensions.Samples(timeStep, inStream.SampleRate);
            noise = Measurement.FromArray(rand(1, samples), 'V');
            inData = InputData(noise, inStream.SampleRate, daqController.Clock.Now);
        end

        input.Add(inStream, inData);
    end
end