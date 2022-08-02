/**
 *Submitted for verification at polygonscan.com on 2022-08-02
*/

// File: contracts/proxy/authority/ITREXImplementationAuthority.sol

// SPDX-License-Identifier: GPL-3.0
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2021, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity ^0.8.0;

interface ITREXImplementationAuthority {
    function getTokenImplementation() external view returns (address);

    function setTokenImplementation(address _tokenImplementation) external;

    function getCTRImplementation() external view returns (address);

    function setCTRImplementation(address _ctrImplementation) external;

    function getIRImplementation() external view returns (address);

    function setIRImplementation(address _irImplementation) external;

    function getIRSImplementation() external view returns (address);

    function setIRSImplementation(address _irsImplementation) external;

    function getTIRImplementation() external view returns (address);

    function setTIRImplementation(address _tirImplementation) external;

    function getMCImplementation() external view returns (address);

    function setMCImplementation(address _mcImplementation) external;
}

// File: contracts/proxy/ModularComplianceProxy.sol
//
//                                             :+#####%%%%%%%%%%%%%%+
//                                         .-*@@@%+.:+%@@@@@%%#***%@@%=
//                                     :=*%@@@#=.      :#@@%       *@@@%=
//                       .-+*%@%*-.:+%@@@@@@+.     -*+:  .=#.       :%@@@%-
//                   :=*@@@@%%@@@@@@@@@%@@@-   .=#@@@%@%=             [email protected]@@@#.
//             -=+#%@@%#*=:.  :%@@@@%.   -*@@#*@@@@@@@#=:-              *@@@@+
//            [email protected]@%=:.     :=:   *@@@@@%#-   =%*%@@@@#+-.        =+       :%@@@%-
//           [email protected]@%.     [email protected]@@     =+=-.         @@#-           [email protected]@@%-       [email protected]@@@%:
//          :@@@.    [email protected]@#%:                   :    .=*=-::.-%@@@+*@@=       [email protected]@@@#.
//          %@@:    [email protected]%%*                         =%@@@@@@@@@@@#.  .*@%-       [email protected]@@@*.
//         #@@=                                [email protected]@@@%:=*@@@@@-      :%@%:      .*@@@@+
//        *@@*                                [email protected]@@#[email protected]@%-:%@@*          [email protected]@#.      :%@@@@-
//       [email protected]@%           .:-=++*##%%%@@@@@@@@@@@@*. :@[email protected]@@%:            .#@@+       [email protected]@@@#:
//      [email protected]@@*-+*#%%%@@@@@@@@@@@@@@@@%%#**@@%@@@.   *@=*@@#                :#@%=      .#@@@@#-
//      -%@@@@@@@@@@@@@@@*+==-:[email protected]@@=    *@# .#@*-=*@@@@%=                 -%@@@*       [email protected]@@@@%-
//         -+%@@@#.   %@%%=   [email protected]@:[email protected]: [email protected]@*    *@@*-::                   -%@@%=.         .*@@@@@#
//            *@@@*  [email protected]* *@@##@@-  #@*@@+    [email protected]@=          .         :[email protected]@@#:           [email protected]@@%+-
//             [email protected]@@%*@@:[email protected]@@@*   [email protected]@@*   .#@#.       .=+-       .=%@@@*.         :+#@@@@*=:
//              [email protected]@@@%@@@@@@@@@@@@@@@@@@@@@@%-      :+#*.       :*@@@%=.       .=#@@@@%+:
//               .%@@=                 .....    .=#@@+.       .#@@@*:       -*%@@@@%+.
//                 [email protected]@#+===---:::...         .=%@@*-         [email protected]@@+.      -*@@@@@%+.
//                  [email protected]@@@@@@@@@@@@@@@@@@@@@%@@@@=          [email protected]@@+      -#@@@@@#=.
//                    ..:::---===+++***###%%%@@@#-       .#@@+     -*@@@@@#=.
//                                           @@@@@@+.   [email protected]@*.   [email protected]@@@@%=.
//                                          [email protected]@@@@=   [email protected]@%:   -#@@@@%+.
//                                          [email protected]@@@@. [email protected]@@=  [email protected]@@@@*:
//                                          #@@@@#:%@@#. :*@@@@#-
//                                          @@@@@%@@@= :#@@@@+.
//                                         :@@@@@@@#.:#@@@%-
//                                         [email protected]@@@@@-.*@@@*:
//                                         #@@@@#[email protected]@@+.
//                                         @@@@+-%@%=
//                                        :@@@#%@%=
//                                        [email protected]@@@%-
//                                        :#%%=
//
/**
 *     NOTICE
 *
 *     The T-REX software is licensed under a proprietary license or the GPL v.3.
 *     If you choose to receive it under the GPL v.3 license, the following applies:
 *     T-REX is a suite of smart contracts developed by Tokeny to manage and transfer financial assets on the ethereum blockchain
 *
 *     Copyright (C) 2021, Tokeny sàrl.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

contract ModularComplianceProxy {
    address public implementationAuthority;

    constructor(address _implementationAuthority) {
        implementationAuthority = _implementationAuthority;

        address logic = (ITREXImplementationAuthority(implementationAuthority)).getMCImplementation();

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = logic.delegatecall(abi.encodeWithSignature('init()'));
        require(success, 'Initialization failed.');
    }

    fallback() external payable {
        address logic = (ITREXImplementationAuthority(implementationAuthority)).getMCImplementation();

        assembly {
        // solium-disable-line
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(sub(gas(), 10000), logic, 0x0, calldatasize(), 0, 0)
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }
}