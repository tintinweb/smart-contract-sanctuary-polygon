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
    uint256 constant alphax  = 9208877235461326938535802987244285376069796937238009493433171890769379369603;
    uint256 constant alphay  = 16863629029208568790873301964375507623782240461774495292113736773282732835976;
    uint256 constant betax1  = 6469233410493468173157048265442122919793521719387837497647709661768665021748;
    uint256 constant betax2  = 4322528869178961746169177885252489658997579832162547002296292167117442895058;
    uint256 constant betay1  = 18551594639048861071322272313692193153157469549223204416938970272974221784080;
    uint256 constant betay2  = 4301216686903067509232806783736092189778585009667002375383362046046377348662;
    uint256 constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 = 11431905845775737710159910866525691314438845665263146413480529179212978893909;
    uint256 constant deltax2 = 10260813894070694790657246026258425955458092410595777027163056757094665120551;
    uint256 constant deltay1 = 2902140926567969756848594744040067338589997354693680532595605666131591431998;
    uint256 constant deltay2 = 16745727771866616200126458523331999885203427100677708652543416191370600601818;

    
    uint256 constant IC0x = 15388757332623256794593239362437708282012823741989713348510659556986923846362;
    uint256 constant IC0y = 674909651210359281539767385871480919100836847853983978100144198064617407365;
    
    uint256 constant IC1x = 20923825123462473813627686326933647250393220513958286771141024067898633768639;
    uint256 constant IC1y = 10473335723416974306583915651568205564793017924691445915652078439806716116750;
    
    uint256 constant IC2x = 15969324360758049607185576886044537762254638238757263028044867162171483933826;
    uint256 constant IC2y = 19473142317168322041356143960438512996392597456882984980102947525896408853239;
    
    uint256 constant IC3x = 17012672403757423888602386148083687482784468388862830230856985686173961326289;
    uint256 constant IC3y = 3643751654226441814807005976606747792628880004992345766348073497634944386008;
    
    uint256 constant IC4x = 5032257295738237194958224693688278538511952819717347760865599265654914820310;
    uint256 constant IC4y = 17304915837391244388751625452166432656469078264085429796428164421280196308337;
    
    uint256 constant IC5x = 5045003657402950061380148644789704740089144254792006917489260148898654345078;
    uint256 constant IC5y = 4421203257941783827275374846481240532924218161578315389550841730589297635101;
    
    uint256 constant IC6x = 18790419443786035691430849778190929873751214670276789166829109222141133614744;
    uint256 constant IC6y = 15450198708347718508781129380176692488869286982998695944161967229080326498310;
    
    uint256 constant IC7x = 2633864676325762468125901183171688559107618684168303188867351856254483147887;
    uint256 constant IC7y = 15803103436200973323748617068511059499868631445405304306670136452603687021659;
    
    uint256 constant IC8x = 11497078733630216973030219018617637064536179241174512957786833575440787474165;
    uint256 constant IC8y = 988857392805354232336592508253035692862961156880833654838324143714019269552;
    
    uint256 constant IC9x = 15161068372043839307422965358353911559722839139158055013209503637519122690872;
    uint256 constant IC9y = 14633090181213009978843877250987475983066339042844059373459052371884734370435;
    
    uint256 constant IC10x = 19890020460641788378391865136760595371877012002171918513348657040894694670805;
    uint256 constant IC10y = 16583419256073614120484651793226538056194032044444992270737553147932999876214;
    
 
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