% Create a sub-class of this class to define a non-continuous protocol.

classdef NoncontinuousProtocol < SymphonyProtocol
    
    properties (Access = private)
        intervalDuration = 0
        intervalStart
    end
    
    methods
        
        function queueInterval(obj, durationInSeconds)
            obj.intervalDuration = obj.intervalDuration + durationInSeconds;
        end
        
        
        function completeEpoch(obj, epoch)
            % Record the start time of the interval.
            obj.intervalStart = tic;
            
            completeEpoch@SymphonyProtocol(obj, epoch);
        end
        
        
        function preloadQueue(obj) %#ok<MANU>
            % Do nothing.
        end
        
        
        function willQueueEpoch(obj, epoch)
            willQueueEpoch@SymphonyProtocol(obj, epoch);
            
            if obj.numEpochsQueued > 0 && obj.intervalDuration > 0
                % Pause for the remaining interval before queuing the next epoch.
                
                elapsed = toc(obj.intervalStart);
                
                if elapsed < obj.intervalDuration
                    pause(obj.intervalDuration - elapsed);
                else
                    warning('The requested interval was exceeded.');
                end
            end
            
            % Reset interval.
            obj.intervalDuration = 0;
        end
        
        
        function waitToContinueQueuing(obj)
            
            % Wait after each epoch is queued until the epoch is completed.
            while obj.numEpochsQueued > obj.numEpochsCompleted && strcmp(obj.state, 'running')
                pause(0.01);
            end
        end
        
    end
    
end

