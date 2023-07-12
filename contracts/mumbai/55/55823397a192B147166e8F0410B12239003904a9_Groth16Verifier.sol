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
    uint256 constant alphax  = 8698887097548284655415635755443765044043561828935692499820602421188069500821;
    uint256 constant alphay  = 497708273398292213659288442261082057419896194267179888520118665569278757538;
    uint256 constant betax1  = 14962139815675351152146118673251709425766895001891086709987277829323270254992;
    uint256 constant betax2  = 3310344820721748726482627907995002933453325268864420793667064975956828695474;
    uint256 constant betay1  = 15941965110571304442667480997041801427606558259558277277501771681556732652444;
    uint256 constant betay2  = 15000895449902668445474393936033854026957109027255857224631704606791602858958;
    uint256 constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 = 13999534881967248886051248021864500458356394195692708867576927117350809222342;
    uint256 constant deltax2 = 1126095521203380888041667843964312570597908366813804321500433085029316216609;
    uint256 constant deltay1 = 11842033410180852145236086990653706239301584592234682410664414829730800295261;
    uint256 constant deltay2 = 18351422629981400357747673616618557966388144694574394536228324464519459907228;

    
    uint256 constant IC0x = 1973411881860469465946139264024303858965959766264009092430526736067876724541;
    uint256 constant IC0y = 17556099005215713620821456639423777579852453992545726436105563152750888970413;
    
    uint256 constant IC1x = 8433705134542189998295711418640792992665110764597479098833362791741776843578;
    uint256 constant IC1y = 21217625450209404145744162828589351126323094881484322178556159575180472585396;
    
    uint256 constant IC2x = 12018761153738644271524753884069386967714464558311297662320589262891799619750;
    uint256 constant IC2y = 2555059861818314765160683670651541751678627943611829067695668978236093402232;
    
    uint256 constant IC3x = 13542973302361704385534003808415261126741712915864665106595817412827197252791;
    uint256 constant IC3y = 8468752434956947320144866968576529893867501871656493294285655984322761266104;
    
    uint256 constant IC4x = 552789768503642163211405201914940515197893973058469400463094486417668388315;
    uint256 constant IC4y = 352305946158005685708841370259504361684375183519720995659383314745692542760;
    
    uint256 constant IC5x = 4082504905665166583700586004699709472007195332151645084754914528966096851475;
    uint256 constant IC5y = 1676938459891811861447239579144625106507851858216875151359961806503116159525;
    
    uint256 constant IC6x = 1180006216740416905106506975712514671936808973553427298433307263548542150221;
    uint256 constant IC6y = 7101121697150350937776281959474293263488410373870501091151782138642820434563;
    
    uint256 constant IC7x = 7163537267043542401575956321813472234031119004890839617042061772997924024585;
    uint256 constant IC7y = 11113337109391531050236173210445847160772746629339588662713885641142918705715;
    
    uint256 constant IC8x = 21841630270028480069309069532739758603210794390384843298504853714512593832055;
    uint256 constant IC8y = 6196911846764232421845480067686138530754709479613224572568423844115083620260;
    
    uint256 constant IC9x = 9240348288576289887526643504031892642026783177251336041928948541527796434022;
    uint256 constant IC9y = 17457941002076880383726652500492466852833530535851070656539985070671082800804;
    
    uint256 constant IC10x = 4876327841126908088386647043758741900377125762787804069716521142985238738183;
    uint256 constant IC10y = 7343001316673517854783301702360222145694171891234422607273670869293339332466;
    
    uint256 constant IC11x = 18366199123557099716194299951329965094213705078530962921637795866968259166994;
    uint256 constant IC11y = 7678140170893519715577472339338281724161838180677353203037263742730426181209;
    
    uint256 constant IC12x = 13468745640814197174849003675845296509135077247050474005069645597527076564296;
    uint256 constant IC12y = 20386276953907974650867194803401659609413319359599246821985386470182487092696;
    
    uint256 constant IC13x = 20567536098793719145391981171868178088075928716148349090788972377814399838001;
    uint256 constant IC13y = 6895078104768944506071031156849120228287686991135328441443992481384513642027;
    
    uint256 constant IC14x = 12523457481312436189748298061293725910774510106151763809440326502124400617283;
    uint256 constant IC14y = 19561831528906195634313715012177987725121500150252471404834035314805295034275;
    
    uint256 constant IC15x = 754555085539927034660764924609688162763245371396659115950829189587046780325;
    uint256 constant IC15y = 2764869647246858565478085645765758192252244024455597203038884397703846024821;
    
    uint256 constant IC16x = 8060116073881299544097528595313544111184531755078037792270146139093367247904;
    uint256 constant IC16y = 11880077961011447730603616468708698533791170935765165953872730922946716350707;
    
    uint256 constant IC17x = 17604443952736062752416073228432278128728247520371121760588342020421718454633;
    uint256 constant IC17y = 9666524390000700238523246168017689998011558023178920220806987741354504948498;
    
    uint256 constant IC18x = 7378206012105896043605073710707934732623852420885900362577946562593445147113;
    uint256 constant IC18y = 9336763485296675238029783208763235769724918410221289811718679709746744249850;
    
    uint256 constant IC19x = 7645377623170652631452355234306272462360724902274024797576617278314477942350;
    uint256 constant IC19y = 18195301090735216181857745865917442488141234911091912472603288467988881358813;
    
    uint256 constant IC20x = 19270393558647876270170401366654689299608475137848679433561052846277558161605;
    uint256 constant IC20y = 14015157596621351381412689794229801078895399386576636896571981417056392783741;
    
    uint256 constant IC21x = 16552085356338143783683145950070380168220088292773333687817315016597053355863;
    uint256 constant IC21y = 18722869490769625545182629057597147483012624107291372409769149969116032187081;
    
    uint256 constant IC22x = 5912976111375174516178873536731782791409094547850137263746435931790636870130;
    uint256 constant IC22y = 8618280638005212710705012090642421724225788645072972301300329541637602300027;
    
    uint256 constant IC23x = 7151727564299056344219498135503721623160821496204025806248452932410015099321;
    uint256 constant IC23y = 12383547911164913572420680100049547838956833465091516507019797630078981995990;
    
    uint256 constant IC24x = 11387705721234426907262912956243793950991306422216819364224759427486693039048;
    uint256 constant IC24y = 13336252639910854769905290442977606203977669028989264799944465896424626874096;
    
    uint256 constant IC25x = 15801687092325201172028951974671199951065838499228445724177369162944429639947;
    uint256 constant IC25y = 20499218811760275068315971156266323520841930741016837083903942613043767683350;
    
    uint256 constant IC26x = 5023700891396152711139592245907792281261463553096697221419268766796773478607;
    uint256 constant IC26y = 1626824067128147035209505191932304397419266350470178725016015043097062359008;
    
    uint256 constant IC27x = 8125761600274340432566290314818363954481922131271295046442187388316664684019;
    uint256 constant IC27y = 10489069883778191275237393730370301061912994420826641224211869933359645286081;
    
    uint256 constant IC28x = 4791242976793337821069543469865691523188774903816207231810621598910212576884;
    uint256 constant IC28y = 11403290276658368773339951480165470214209810048537545399640827312206008710011;
    
    uint256 constant IC29x = 20099581084179218262672906437021171948077888999235785200824982745700314084588;
    uint256 constant IC29y = 1385490472945051846746407082460925599680290639116639215341130611273042343849;
    
    uint256 constant IC30x = 780500165461554553878540201168543078550490200774986603757835496707046588075;
    uint256 constant IC30y = 12958390475801524471818383051771072865613789910147833245168272930303596334517;
    
    uint256 constant IC31x = 12186960164416466493808718565798747235361038177493384485819658516527173667768;
    uint256 constant IC31y = 20031031288102112054733063306705573926677917419439117665401089911069354723812;
    
    uint256 constant IC32x = 10497931378507841831926222734199848403461269493607143241715978098330349601501;
    uint256 constant IC32y = 17583667433485986857963767613643360692629942147603668045527037774927408235159;
    
    uint256 constant IC33x = 885852890989775745473598369683221059103732405699853663763666961939448782582;
    uint256 constant IC33y = 11386992941616252907691280508406207780751873078168436161723539705501204633536;
    
    uint256 constant IC34x = 10355560411320903710383077823081785286936224989324172647171552205094745861619;
    uint256 constant IC34y = 12914871635257383875040945177186626922357530660770280053480142740383297032943;
    
    uint256 constant IC35x = 5069726941668900707851882752435237419270542574677596429968290512176241712710;
    uint256 constant IC35y = 9461568707771783040392450708887928559077038013773657435856312033667109977232;
    
    uint256 constant IC36x = 7991641392330617852400628514111978613941880121445804022560185800290062167403;
    uint256 constant IC36y = 9165533731762083133099621253141593498798679660607552965001522891557068505875;
    
    uint256 constant IC37x = 11414425036151070413004605049652881515631791312885088629030973039507901075818;
    uint256 constant IC37y = 11467377133171323754388409482537321977444629467703204166745926190564267327235;
    
    uint256 constant IC38x = 358405769790897516183655907943006566358942931874509796795628505395868607526;
    uint256 constant IC38y = 10775092660222303918003512314344509301740983706509747644968389192955403674692;
    
    uint256 constant IC39x = 5332603483922782086114095180816885445345469999813237664982079953289701073373;
    uint256 constant IC39y = 9038559874335326994946936539339574060695834297204606226878617956832088528513;
    
    uint256 constant IC40x = 3012914622114110693654968778387234900529268250181763626639289318766127501731;
    uint256 constant IC40y = 13780456481949036994210850165249014608572882759581738184149974490272689204863;
    
    uint256 constant IC41x = 17856619246946113460710657874394908244799912700290979375777107091959370456592;
    uint256 constant IC41y = 13489507643454887120186563710777917547217190041466017067145836687683014062887;
    
    uint256 constant IC42x = 5774531413213405674413052492354727376783744945829588435125688709054586259781;
    uint256 constant IC42y = 6912995371926485106082766294030680831451415601896195336556844012914131572211;
    
 
    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[42] calldata _pubSignals) public view returns (bool) {
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
                
                g1_mulAccC(_pVk, IC11x, IC11y, calldataload(add(pubSignals, 320)))
                
                g1_mulAccC(_pVk, IC12x, IC12y, calldataload(add(pubSignals, 352)))
                
                g1_mulAccC(_pVk, IC13x, IC13y, calldataload(add(pubSignals, 384)))
                
                g1_mulAccC(_pVk, IC14x, IC14y, calldataload(add(pubSignals, 416)))
                
                g1_mulAccC(_pVk, IC15x, IC15y, calldataload(add(pubSignals, 448)))
                
                g1_mulAccC(_pVk, IC16x, IC16y, calldataload(add(pubSignals, 480)))
                
                g1_mulAccC(_pVk, IC17x, IC17y, calldataload(add(pubSignals, 512)))
                
                g1_mulAccC(_pVk, IC18x, IC18y, calldataload(add(pubSignals, 544)))
                
                g1_mulAccC(_pVk, IC19x, IC19y, calldataload(add(pubSignals, 576)))
                
                g1_mulAccC(_pVk, IC20x, IC20y, calldataload(add(pubSignals, 608)))
                
                g1_mulAccC(_pVk, IC21x, IC21y, calldataload(add(pubSignals, 640)))
                
                g1_mulAccC(_pVk, IC22x, IC22y, calldataload(add(pubSignals, 672)))
                
                g1_mulAccC(_pVk, IC23x, IC23y, calldataload(add(pubSignals, 704)))
                
                g1_mulAccC(_pVk, IC24x, IC24y, calldataload(add(pubSignals, 736)))
                
                g1_mulAccC(_pVk, IC25x, IC25y, calldataload(add(pubSignals, 768)))
                
                g1_mulAccC(_pVk, IC26x, IC26y, calldataload(add(pubSignals, 800)))
                
                g1_mulAccC(_pVk, IC27x, IC27y, calldataload(add(pubSignals, 832)))
                
                g1_mulAccC(_pVk, IC28x, IC28y, calldataload(add(pubSignals, 864)))
                
                g1_mulAccC(_pVk, IC29x, IC29y, calldataload(add(pubSignals, 896)))
                
                g1_mulAccC(_pVk, IC30x, IC30y, calldataload(add(pubSignals, 928)))
                
                g1_mulAccC(_pVk, IC31x, IC31y, calldataload(add(pubSignals, 960)))
                
                g1_mulAccC(_pVk, IC32x, IC32y, calldataload(add(pubSignals, 992)))
                
                g1_mulAccC(_pVk, IC33x, IC33y, calldataload(add(pubSignals, 1024)))
                
                g1_mulAccC(_pVk, IC34x, IC34y, calldataload(add(pubSignals, 1056)))
                
                g1_mulAccC(_pVk, IC35x, IC35y, calldataload(add(pubSignals, 1088)))
                
                g1_mulAccC(_pVk, IC36x, IC36y, calldataload(add(pubSignals, 1120)))
                
                g1_mulAccC(_pVk, IC37x, IC37y, calldataload(add(pubSignals, 1152)))
                
                g1_mulAccC(_pVk, IC38x, IC38y, calldataload(add(pubSignals, 1184)))
                
                g1_mulAccC(_pVk, IC39x, IC39y, calldataload(add(pubSignals, 1216)))
                
                g1_mulAccC(_pVk, IC40x, IC40y, calldataload(add(pubSignals, 1248)))
                
                g1_mulAccC(_pVk, IC41x, IC41y, calldataload(add(pubSignals, 1280)))
                
                g1_mulAccC(_pVk, IC42x, IC42y, calldataload(add(pubSignals, 1312)))
                

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
            
            checkField(calldataload(add(_pubSignals, 352)))
            
            checkField(calldataload(add(_pubSignals, 384)))
            
            checkField(calldataload(add(_pubSignals, 416)))
            
            checkField(calldataload(add(_pubSignals, 448)))
            
            checkField(calldataload(add(_pubSignals, 480)))
            
            checkField(calldataload(add(_pubSignals, 512)))
            
            checkField(calldataload(add(_pubSignals, 544)))
            
            checkField(calldataload(add(_pubSignals, 576)))
            
            checkField(calldataload(add(_pubSignals, 608)))
            
            checkField(calldataload(add(_pubSignals, 640)))
            
            checkField(calldataload(add(_pubSignals, 672)))
            
            checkField(calldataload(add(_pubSignals, 704)))
            
            checkField(calldataload(add(_pubSignals, 736)))
            
            checkField(calldataload(add(_pubSignals, 768)))
            
            checkField(calldataload(add(_pubSignals, 800)))
            
            checkField(calldataload(add(_pubSignals, 832)))
            
            checkField(calldataload(add(_pubSignals, 864)))
            
            checkField(calldataload(add(_pubSignals, 896)))
            
            checkField(calldataload(add(_pubSignals, 928)))
            
            checkField(calldataload(add(_pubSignals, 960)))
            
            checkField(calldataload(add(_pubSignals, 992)))
            
            checkField(calldataload(add(_pubSignals, 1024)))
            
            checkField(calldataload(add(_pubSignals, 1056)))
            
            checkField(calldataload(add(_pubSignals, 1088)))
            
            checkField(calldataload(add(_pubSignals, 1120)))
            
            checkField(calldataload(add(_pubSignals, 1152)))
            
            checkField(calldataload(add(_pubSignals, 1184)))
            
            checkField(calldataload(add(_pubSignals, 1216)))
            
            checkField(calldataload(add(_pubSignals, 1248)))
            
            checkField(calldataload(add(_pubSignals, 1280)))
            
            checkField(calldataload(add(_pubSignals, 1312)))
            
            checkField(calldataload(add(_pubSignals, 1344)))
            

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }