data = rand(12,1);
sampleRate = 200;   %hz
tt = timetable(data,'SampleRate', sampleRate);



%Note, converted to seconds
timeSamples = seconds(0 : 1/sampleRate : (size(data)-1)/sampleRate);
tt = timetable(timeSamples', data);


%NaN
data = rand(1e7,1);
timeSamples = seconds(0 : 1/sampleRate : (size(data)-1)/sampleRate);
timeSamples(2) = seconds(0);
tt = timetable(timeSamples', data);




%NAN Sample Rate
MeasurementTime = datetime({'2015-12-18 08:03:05';'2015-12-18 10:03:17';'2015-12-18 12:03:13'});
Temp = [37.3;39.1;42.3];
Pressure = [30.1;30.03;29.9];
WindSpeed = [13.4;6.5;7.3];
WindDirection = categorical({'NW';'N';'NW'});
TT = timetable(MeasurementTime,Temp,Pressure,WindSpeed,WindDirection)