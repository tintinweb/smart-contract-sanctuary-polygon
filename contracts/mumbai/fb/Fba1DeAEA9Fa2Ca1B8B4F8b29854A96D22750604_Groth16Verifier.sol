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
    uint256 constant alphax  = 14612766098852225058551700114211492080588370334689001136689800261994627916838;
    uint256 constant alphay  = 7078756318604975248396280161024793726141402670722018710363650096909181916557;
    uint256 constant betax1  = 20585606898898412702759234404844070892628783449827087414438687878057170835154;
    uint256 constant betax2  = 10135066260212937967357753483531483827065203440925368326038176584292199674013;
    uint256 constant betay1  = 4713928957698673906563134936428693638626235465864672820140499089978641299619;
    uint256 constant betay2  = 19454466298506833977787710535429410267391402867979322893921995834807555062883;
    uint256 constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 = 21487609652475360143071334063798565427660250244080325153064101564944473551586;
    uint256 constant deltax2 = 6807330549011096239535237923139138948222062654800007255095317940457905293077;
    uint256 constant deltay1 = 20688140255803357315688725748220387884946474796410207570581830704811732528995;
    uint256 constant deltay2 = 12550830197048818129958549642613979137317668869763514286655417238798129545586;

    
    uint256 constant IC0x = 19782314369995596755439443533822109475757228888773425328216879279770768684656;
    uint256 constant IC0y = 12862098695948578084782387923893908251047695352036305579049496769141060226533;
    
    uint256 constant IC1x = 950945323386122216236439997832603070645596700631528381736339005773674116335;
    uint256 constant IC1y = 15144011377211916872452214064166730222864642845257593830154069394193637258431;
    
    uint256 constant IC2x = 4046324005483250131458575662982613256364024440697964672699210761246003886134;
    uint256 constant IC2y = 884938293875853991639546406483258529432912552066748075526795678410475072894;
    
    uint256 constant IC3x = 12694587566332838626311371143617160950018151596089539819126934736543243022903;
    uint256 constant IC3y = 1118764461494385377435177000525428129711023340259192866784316758478396755882;
    
    uint256 constant IC4x = 19095124239489760820304118988311067545969819741112758857565630363979183202838;
    uint256 constant IC4y = 15332531160135096558976610461069462789525432921808322806906353474200812934114;
    
    uint256 constant IC5x = 1310289500983279991477682718884650884700269132678404095684437165678296665247;
    uint256 constant IC5y = 14838243765968177952917281158064647345830536614776991485602081285640713548486;
    
    uint256 constant IC6x = 15713040391427041878895397216862001535375011200729737025924868523017044273935;
    uint256 constant IC6y = 18081642455875337915606658821295680969757936467422766257464023929879991525129;
    
    uint256 constant IC7x = 18371667049677028646391009861300307380332262570173014010443382924995434570513;
    uint256 constant IC7y = 3733719746262420619745867466927464987484631992748507892135184513425054907032;
    
    uint256 constant IC8x = 9186651072421859438013190319056113499033448388761009942116626861938630719858;
    uint256 constant IC8y = 16434990865538748323322075044428348390952522777892155944307766793117369928151;
    
    uint256 constant IC9x = 8310030417769142871871171033430364837202429520082782111245685703452433923837;
    uint256 constant IC9y = 3790219474210712155040647654067125617243874006415030345843979131254275086161;
    
    uint256 constant IC10x = 3101216841489857318129869100643264989906795077204106771068272443085835099733;
    uint256 constant IC10y = 3059238168182914922650139641251799490666702598806639481548722105876823906077;
    
 
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