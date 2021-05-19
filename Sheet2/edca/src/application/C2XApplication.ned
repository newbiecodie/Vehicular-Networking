//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public License
// along with this program.  If not, see http://www.gnu.org/licenses/.
// 

package edca.application;
import org.car2x.veins.base.modules.IBaseApplLayer;

simple C2XApplication like IBaseApplLayer
{
    parameters:
        @class(C2XApplication);
        int headerLength = default(88bit) @unit(bit); //header length of the application
        int packetLength = default(1024bit) @unit("bit"); //packet length of the application

        volatile double arrival_vo = default(1s) @unit(s); // inter-arrival time of packets in AC_VO
        volatile double arrival_vi = default(1s) @unit(s); // inter-arrival time of packets in AC_VI
        volatile double arrival_be = default(1s) @unit(s); // inter-arrival time of packets in AC_BE
        volatile double arrival_bk = default(1s) @unit(s); // inter-arrival time of packets in AC_BK
        
        bool sendViaVO = default(false); // generate AC_VO traffic only when true
        bool sendViaVI = default(false); // generate AC_VI traffic only when true
        bool sendViaBE = default(false); // generate AC_BE traffic only when true
        bool sendViaBK = default(false); // generate AC_BK traffic only when true
        
        @signal[delayVO](type="simtime_t");
        @statistic[delayVO](title="delayVO"; source=delayVO; record=vector; interpolationmode=none);
        
        @signal[delayVI](type="simtime_t");
        @statistic[delayVI](title="delayVI"; source=delayVI; record=vector; interpolationmode=none);
        
        @signal[delayBE](type="simtime_t");
        @statistic[delayBE](title="delayBE"; source=delayBE; record=vector; interpolationmode=none);
        
        @signal[delayBK](type="simtime_t");
        @statistic[delayBK](title="delayBK"; source=delayBK; record=vector; interpolationmode=none);
        
        @signal[countVO](type="int");
        @statistic[countVO](title="countVO"; source=countVO; record=vector; interpolationmode=none);
        
        @signal[countVI](type="int");
        @statistic[countVI](title="countVI"; source=countVI; record=vector; interpolationmode=none);
        
        @signal[countBE](type="int");
        @statistic[countBE](title="countBE"; source=countBE; record=vector; interpolationmode=none);
        
        @signal[countBK](type="int");
        @statistic[countBK](title="countBK"; source=countBK; record=vector; interpolationmode=none);        
    gates:
        input lowerLayerIn; // from mac layer
        output lowerLayerOut; // to mac layer
        input lowerControlIn;
        output lowerControlOut;
        
}
