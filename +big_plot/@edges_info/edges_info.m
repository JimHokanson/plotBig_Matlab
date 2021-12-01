classdef edges_info < handle
    %
    %   Class:
    %   big_plot.edges_info
    %
    %   This class holds info on edge data for plotting. Ideally
    %   when a zoom is made we could just plot only the visible data.
    %   Unfortunately, if the axes is listening for a data change, it may
    %   discover that the new data are not as expansive as previously
    %   thought, and may zoom in further. 
    %
    %   The new code tries to always plot anchor points on the left and
    %   right side that prevent zooming in or out. 
    %
    %   This however is really tricky if you include NaNs, as your anchor
    %   point can no longer be the first and last point, as those may not
    %   be valid.
    %
    %   This code tries to establish the first and last valid points
    %   on data setup as this doesn't change, but is needed everytime
    %   the zoom level changes.
    
    properties
        x_values
        y_values
        %
        
        x_t1
        x_tend
        x_I1
        x_Iend
        %1x2
        output_x_left
        output_x_right
        %Format
        %2 x n_chans
        output_y_left
        output_y_right
        nans_only = false
    end
    
    methods
        function obj = edges_info(x,y)
            %
            %   obj = big_plot.edges_info(x,y)
            if isobject(y)
                return
            end
            
            n_samples = size(y,1);
            n_chans = size(y,2);
            
            if isinteger(y)
                %Integers don't have NANs!!!!
                x1 = big_plot.utils.indexToTime(x,1);
                xend = big_plot.utils.indexToTime(x,n_samples);

                obj.x_t1 = x1;
                obj.x_tend = xend;
                obj.x_I1 = 1;
                obj.x_Iend = n_samples;
                
                obj.output_x_left = repmat(x1,1,2);
                obj.output_x_right = repmat(xend,1,2);
                obj.output_y_left = repmat(y(1,:),2,1);
                obj.output_y_right = repmat(y(end,:),2,1);
                return
            end
            
            
            %format
            %n_chans x 2 -> [left right]
            temp_I = NaN(n_chans,2);
            
            %X could be an array, datetime, duration, or object
            %so we have a helper function to intialize
            temp_x = big_plot.utils.getXInit(x,[n_chans,2]);
            temp_y = NaN(n_chans,2,'like',y);
            for i = 1:n_chans
                I = find(~isnan(y(:,i)),1,'first');
                if ~isempty(I)
                    temp_I(i,1) = I;
                    temp_x(i,1) = big_plot.utils.indexToTime(x,I);
                    temp_y(i,1) = y(I,i);
                end
                I = find(~isnan(y(:,i)),1,'last');
                if ~isempty(I)
                    temp_I(i,2) = I;
                    temp_x(i,2) = big_plot.utils.indexToTime(x,I);
                    temp_y(i,2) = y(I,i);
                end
            end
            
            if all(isnan(temp_I(:)))
                obj.nans_only = true;
                return
            end
            
            %Note, we don't need to anchor each channel to its left
            %or right most valid point, because any channel that 
            %is furthest out will anchor the rest
            %
            %That's why below we look for the left and right most 
            %valid points, and just grab all channels at that point, even
            %though some channels may not be valid at that point.
            [~,I] = min(temp_x(:,1));
            obj.x_t1 = temp_x(I,1);
            obj.x_I1 = temp_I(I,1);
            obj.output_x_left = repmat(obj.x_t1,1,2);
            obj.output_y_left = NaN(2,n_chans);
            obj.output_y_left(1:2,I) = temp_y(I,1);
            
            [~,I] = max(temp_x(:,2));
        	obj.x_tend = temp_x(I,2);
            obj.x_Iend = temp_I(I,2);
            obj.output_x_right = repmat(obj.x_tend,1,2);
            obj.output_y_right = NaN(2,n_chans);
            obj.output_y_right(1:2,I) = temp_y(I,2);
            
            obj.x_values = temp_x;
            obj.y_values = temp_y;
        end
        function [x,y] = getPadValues(obj)
            %
            %   Cases:
            %   - single, double
            %   - for left most valid y, for that channel use 
            %     corresponding x, left most valid y
            %   - same for right most valid y
            %   - for other channels, just include NaNs on y
            %     since we aren't using that point as an anchor point
            %     Note, anything within range is already plotted, this
            %     is just extra to force 
            %
            %   - for integers we don't have NaNs, just use edge values
            
            
            
        end
    end
end

