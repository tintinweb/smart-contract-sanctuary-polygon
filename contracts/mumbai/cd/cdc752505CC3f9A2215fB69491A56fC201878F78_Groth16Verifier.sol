// SPDX-License-Identifier: GPL-3.0
/*
    Copyright 2021 0KIMS association.

    This file is generated with [snarkJS](https://github.com/iden3/snarkjs).

    snarkJS is a free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    snarkJS is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
    License for more details.

    You should have received a copy of the GNU General Public License
    along with snarkJS. If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.7.0 <0.9.0;

contract Groth16Verifier {
    // Scalar field size
    uint256 constant r    = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 constant q   = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
    uint256 constant alphax  = 12695992646413598705515222700926748088765739264062982693017655326644750513612;
    uint256 constant alphay  = 14939233584203977454953372565167149224686965128226137715447397925733977428117;
    uint256 constant betax1  = 18761824090335844073432351626909609908403461825271558075307942671335430265934;
    uint256 constant betax2  = 14017084615493957961103709387199143808675043897628889524894120810021800440601;
    uint256 constant betay1  = 11473201348879440900621411929116362680756555424407671010228061984513754233735;
    uint256 constant betay2  = 19896186915406175476213644531319147970155882313481127054762469290854471659882;
    uint256 constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 = 15085890699907424486908114944729906880531669635461287277928878517995747287386;
    uint256 constant deltax2 = 11859493485352233860662293125317957998355287464528646151281514774067275340597;
    uint256 constant deltay1 = 13979566351876345130788329389921880133939013611692829753952310397760941034800;
    uint256 constant deltay2 = 7405045274239324209129717533969562874225752304076641605984532583284755366068;

    
    uint256 constant IC0x = 373810652249147241689824894441193026251399712874421931270252676753819522778;
    uint256 constant IC0y = 9515227073834926532818526275630040823550453381949951191488629734403948398548;
    
    uint256 constant IC1x = 20976396712228296385795895797503717208983278233943705916502350885810281970533;
    uint256 constant IC1y = 817546586382941304120463060211400931379275014663412441371746641022263757052;
    
    uint256 constant IC2x = 6005135261810374177597187382418611301998304252089120752035596189395599725959;
    uint256 constant IC2y = 1872398028245938460586817250487392877846292468759446503329255393446240206007;
    
    uint256 constant IC3x = 2438084360017350880536144286066904525621069327730510923375915443050678635353;
    uint256 constant IC3y = 11651955657345710510734818072879528102732295846665831482663260423460132571047;
    
    uint256 constant IC4x = 20718742324970448439052733980657142121470263528851404476687240737543110386062;
    uint256 constant IC4y = 12715199918036275542663966435478985095493423122563756258653244360257880527793;
    
    uint256 constant IC5x = 15025049288911936707040053554580182123888258549160116151260592087997484525762;
    uint256 constant IC5y = 20676127328625840239768167429423468230142713535852749780937022570557857343033;
    
    uint256 constant IC6x = 8226896688881306793265999406895838807566942263070257243279909341821875137735;
    uint256 constant IC6y = 7701031365468752039136462827922652243388579091357499385985880864059341018364;
    
    uint256 constant IC7x = 11404926557230404686529089043584637327364909956652361560609473494093932043601;
    uint256 constant IC7y = 13317971275346214873133419732355087441671465410744382392907267957346219977156;
    
    uint256 constant IC8x = 21425487173093524126324750004482687386717265118543730567833253218686065332087;
    uint256 constant IC8y = 13496038320700925618840442918517540276067083387395409426743486196127876238151;
    
    uint256 constant IC9x = 14898271123563040432295200126753944794795353642143387225865067095493272697687;
    uint256 constant IC9y = 9835868533050102167536572058396997765116225075217079494529328839105122352081;
    
    uint256 constant IC10x = 13448188745546099753432116321161187608740887279647114411322658934189637208979;
    uint256 constant IC10y = 10532234318690182758607771779302466891605966102676213756714620825311852916810;
    
 
    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[10] calldata _pubSignals) public view returns (bool) {
        assembly {
            function checkField(v) {
                if iszero(lt(v, q)) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }
            
            // G1 function to multiply a G1 value(x,y) to value in an address
            function g1_mulAccC(pR, x, y, s) {
                let success
                let mIn := mload(0x40)
                mstore(mIn, x)
                mstore(add(mIn, 32), y)
                mstore(add(mIn, 64), s)

                success := staticcall(sub(gas(), 2000), 7, mIn, 96, mIn, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }

                mstore(add(mIn, 64), mload(pR))
                mstore(add(mIn, 96), mload(add(pR, 32)))

                success := staticcall(sub(gas(), 2000), 6, mIn, 128, pR, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            function checkPairing(pA, pB, pC, pubSignals, pMem) -> isOk {
                let _pPairing := add(pMem, pPairing)
                let _pVk := add(pMem, pVk)

                mstore(_pVk, IC0x)
                mstore(add(_pVk, 32), IC0y)

                // Compute the linear combination vk_x
                
                g1_mulAccC(_pVk, IC1x, IC1y, calldataload(add(pubSignals, 0)))
                
                g1_mulAccC(_pVk, IC2x, IC2y, calldataload(add(pubSignals, 32)))
                
                g1_mulAccC(_pVk, IC3x, IC3y, calldataload(add(pubSignals, 64)))
                
                g1_mulAccC(_pVk, IC4x, IC4y, calldataload(add(pubSignals, 96)))
                
                g1_mulAccC(_pVk, IC5x, IC5y, calldataload(add(pubSignals, 128)))
                
                g1_mulAccC(_pVk, IC6x, IC6y, calldataload(add(pubSignals, 160)))
                
                g1_mulAccC(_pVk, IC7x, IC7y, calldataload(add(pubSignals, 192)))
                
                g1_mulAccC(_pVk, IC8x, IC8y, calldataload(add(pubSignals, 224)))
                
                g1_mulAccC(_pVk, IC9x, IC9y, calldataload(add(pubSignals, 256)))
                
                g1_mulAccC(_pVk, IC10x, IC10y, calldataload(add(pubSignals, 288)))
                

                // -A
                mstore(_pPairing, calldataload(pA))
                mstore(add(_pPairing, 32), mod(sub(q, calldataload(add(pA, 32))), q))

                // B
                mstore(add(_pPairing, 64), calldataload(pB))
                mstore(add(_pPairing, 96), calldataload(add(pB, 32)))
                mstore(add(_pPairing, 128), calldataload(add(pB, 64)))
                mstore(add(_pPairing, 160), calldataload(add(pB, 96)))

                // alpha1
                mstore(add(_pPairing, 192), alphax)
                mstore(add(_pPairing, 224), alphay)

                // beta2
                mstore(add(_pPairing, 256), betax1)
                mstore(add(_pPairing, 288), betax2)
                mstore(add(_pPairing, 320), betay1)
                mstore(add(_pPairing, 352), betay2)

                // vk_x
                mstore(add(_pPairing, 384), mload(add(pMem, pVk)))
                mstore(add(_pPairing, 416), mload(add(pMem, add(pVk, 32))))


                // gamma2
                mstore(add(_pPairing, 448), gammax1)
                mstore(add(_pPairing, 480), gammax2)
                mstore(add(_pPairing, 512), gammay1)
                mstore(add(_pPairing, 544), gammay2)

                // C
                mstore(add(_pPairing, 576), calldataload(pC))
                mstore(add(_pPairing, 608), calldataload(add(pC, 32)))

                // delta2
                mstore(add(_pPairing, 640), deltax1)
                mstore(add(_pPairing, 672), deltax2)
                mstore(add(_pPairing, 704), deltay1)
                mstore(add(_pPairing, 736), deltay2)


                let success := staticcall(sub(gas(), 2000), 8, _pPairing, 768, _pPairing, 0x20)

                isOk := and(success, mload(_pPairing))
            }

            let pMem := mload(0x40)
            mstore(0x40, add(pMem, pLastMem))

            // Validate that all evaluations ∈ F
            
            checkField(calldataload(add(_pubSignals, 0)))
            
            checkField(calldataload(add(_pubSignals, 32)))
            
            checkField(calldataload(add(_pubSignals, 64)))
            
            checkField(calldataload(add(_pubSignals, 96)))
            
            checkField(calldataload(add(_pubSignals, 128)))
            
            checkField(calldataload(add(_pubSignals, 160)))
            
            checkField(calldataload(add(_pubSignals, 192)))
            
            checkField(calldataload(add(_pubSignals, 224)))
            
            checkField(calldataload(add(_pubSignals, 256)))
            
            checkField(calldataload(add(_pubSignals, 288)))
            
            checkField(calldataload(add(_pubSignals, 320)))
            

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }