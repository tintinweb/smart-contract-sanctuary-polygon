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
	bool public proofValid = true;
	
	address public owner;
	constructor() public { owner = msg.sender; }
	modifier onlyOwner { require(msg.sender == owner); _; }
	function changeProofValid(bool _proofValid) public onlyOwner { proofValid = _proofValid; }
    // Scalar field size
    uint256 constant r    = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 constant q   = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
    uint256 constant alphax  = 20723641591335862203984160922675953255102533074951847066515712793842742035777;
    uint256 constant alphay  = 19186959961151272243091635421706963366122609386039139917959886994383841316244;
    uint256 constant betax1  = 4385199829580767409139439186569718888542464359030863097858781032641698217248;
    uint256 constant betax2  = 19663316736511377662935385437164086108535841823220458540198374655135008806599;
    uint256 constant betay1  = 15103078699593310424032757641256753603801828960903803791100769777562470186919;
    uint256 constant betay2  = 8183519646075883903664656595261439751314865593537205532240875846732524114249;
    uint256 constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 = 6490889471644156615680740519498069791097399832820173119045826024519455882785;
    uint256 constant deltax2 = 12978247780923114139980164695540734021533710559417716138862921447525652188611;
    uint256 constant deltay1 = 5908166125049732514939353606551446998708710725742629448731475688072373354251;
    uint256 constant deltay2 = 13181663285020324667758059604915116491009692951387081726643199271234656891257;

    
    uint256 constant IC0x = 4027574927699957498484604762553529050240199060846522648936656814766792709146;
    uint256 constant IC0y = 18155362249372171695999696163998240528295990707093184576383966398295608334985;
    
    uint256 constant IC1x = 13454138356785010114979975581834514953106824624881881752945158361459095456026;
    uint256 constant IC1y = 14349442331712288452637242296331734527633026286111407655087164623520464316495;
    
    uint256 constant IC2x = 11532582603889877705382994999653684235614321625305066882353086417269202995995;
    uint256 constant IC2y = 10314705938006367194181039567094525160565311490665250306385802231472109639967;
    
    uint256 constant IC3x = 3121771437812865253084341242600030509896813169879265186681212877042455720079;
    uint256 constant IC3y = 18526983512343875253640357943005680287800598140397748123745431052001754889807;
    
    uint256 constant IC4x = 11255952525163712745729763620425790667259849295983074274541934232527463487096;
    uint256 constant IC4y = 20035591642116440257366917745018770007072333222133304257715130480816699902798;
    
    uint256 constant IC5x = 16259581118073537254407880445698296624547615741817869254552097038531194959111;
    uint256 constant IC5y = 3027800941468685366528449888616362862278727041600880826301603044090358954052;
    
    uint256 constant IC6x = 20062197524615028812804251468436348978358178526612452695397141849529102898862;
    uint256 constant IC6y = 20717871410921310589015647225619767925661490456454278781450327127632025228042;
    
    uint256 constant IC7x = 19599212325109521488615680941754152409291654681507117929410267269299000594085;
    uint256 constant IC7y = 11057723002772208521751711120205287886818047100556162073533187299684148134552;
    
    uint256 constant IC8x = 7364904663567352887461584872991652034985253799263058222895207817181547692038;
    uint256 constant IC8y = 4164523089951435610085796422160889740811903035920351069488970195208853843568;
    
    uint256 constant IC9x = 9333590625768742806964742125734255674467293958841370294923566349837307998744;
    uint256 constant IC9y = 10664553471220405960941333743764697994550020665531888319010889960939585573075;
    
    uint256 constant IC10x = 1074811212278218111039174240657932570830010203658581197964955503855047294810;
    uint256 constant IC10y = 17116917190259599481808909726145557609997634543959113830211103214263754696128;
    
 
    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[10] calldata _pubSignals) public view returns (bool) {
		require(proofValid, "Proof is not valid");
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