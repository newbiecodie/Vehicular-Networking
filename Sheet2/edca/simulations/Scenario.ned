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

package edca.simulations;
import org.car2x.veins.base.connectionManager.ConnectionManager;
import org.car2x.veins.base.modules.BaseWorldUtility;
import org.car2x.veins.modules.world.annotations.AnnotationManager;
import org.car2x.veins.nodes.RSU;

network Scenario
{
    parameters:
        int rsuCount;

        @display("bgb=438,307");
    submodules:
        world: BaseWorldUtility {
            @display("p=36,14");
        }
        connectionManager: ConnectionManager {
            @display("p=36,64");
        }
        annotationManager: AnnotationManager {
            @display("p=92,20");
        }
        rsu[rsuCount]: RSU {
            @display("p=166,212");
        }
    connections allowunconnected:
}
