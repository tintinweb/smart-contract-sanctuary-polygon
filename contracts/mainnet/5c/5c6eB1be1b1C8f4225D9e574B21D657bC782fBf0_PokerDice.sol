/**
 *Submitted for verification at polygonscan.com on 2023-02-02
*/

pragma solidity ^0.8.9;

contract PokerDice {

    address payable owner;
    mapping(address => uint) nonce; 

    uint16[9] private ratios;
    uint maxbet;
    uint minbet;

    event Roll(address indexed addr, uint reward, uint8 d1,uint8 d2,uint8 d3,uint8 d4,uint8 d5, uint bet);

    modifier onlyOwner {
        require(msg.sender == owner, "Sender not authorized!");
        _;
    }

    constructor () {
        owner = payable(msg.sender);
    }

    function finalize() public onlyOwner {
        selfdestruct(owner);
    }

    function sort(uint8[6] memory arr) private pure returns(uint8[6] memory){
        uint i;
        uint8 key;
        uint j;
        for(i = 1; i < arr.length; i++ ) {
            key = arr[i];
            for(j = i; j > 0 && arr[j-1] > key; j-- ) {
                arr[j] = arr[j-1];
            }
            arr[j] = key;
        }
        return arr;
    }

    function getOwner() public view returns(address){
        return owner;
    }

    function transferOwnership(address payable _owner) public onlyOwner {
        owner = _owner;
    }

    function setRatio(uint i, uint16 _ratio) public onlyOwner {
        require(i<9, "Invalid ratio id");
        ratios[i] = _ratio;
    } 

    function getRatios() public view returns(uint16[9] memory) {
        return ratios;
    }

    function withdraw(uint _weis, address payable addr) public payable onlyOwner {
        addr.transfer(_weis);
    }
 
    function setBetLimits(uint _max, uint _min) public onlyOwner {
        require(_max>=_min, "Invalid min max pair");
        maxbet = _max;
        minbet = _min;
    }

    function getBetLimits() public view returns(uint[2] memory) {
        return [maxbet,minbet];
    }

    fallback() external payable  { }

    receive() external payable { }

    function roll() public payable {
        require((msg.value>=minbet) && (msg.value<=maxbet), "Invalid bet size");

        uint8[5] memory d;
        uint8[6] memory p;
        
        uint rnd = uint(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, msg.sender, nonce[msg.sender])));
        
        for (uint8 i=0;i<5;++i){
            d[i] = uint8(uint32((rnd >>(i*32)) & 0xffffffff) % 6);
            p[d[i]]++;
        }

        nonce[msg.sender]++;
        uint reward = 0;
        uint value = msg.value;
        address payable sender = payable(msg.sender);

        if (d[0]==1 && d[1]==2 && d[2]==3 && d[3]==4 && d[4]==5){
            reward = (value*ratios[8])/10;
            sender.transfer(reward);
        }else if (d[0]==0 && d[1]==1 && d[2]==2 && d[3]==3 && d[4]==4){
            reward = (value*ratios[7])/10;
            sender.transfer(reward);
        }else{
            if (p[1]==1 && p[2]==1 && p[3]==1 && p[4]==1 && p[5]==1){
                //high streght
                reward=(value*ratios[5])/10;
                sender.transfer(reward);
            }else if (p[0]==1 && p[1]==1 && p[2]==1 && p[3]==1 && p[4]==1){
                //low streght
                reward=(value*ratios[4])/10;
                sender.transfer(reward);
            }else{
                p = sort(p);
                if (p[5]==5){
                    //five of a kind
                    reward=(value*ratios[6])/10;
                    sender.transfer(reward);
                }else if (p[5]==4){
                    //four of a kind
                    reward=(value*ratios[3])/10;
                    sender.transfer(reward);
                }else if (p[5]==3){
                    if (p[4]==2){
                        //full house
                        reward=(value*ratios[2])/10;
                        sender.transfer(reward);
                    }else{
                        //three of a kind
                        reward=(value*ratios[1])/10;
                        sender.transfer(reward);
                    }
                }else if (p[5]==2 && p[4]==2){
                    //two pairs
                    reward=(value*ratios[0])/10;
                    sender.transfer(reward);
                }

            }
        }

        emit Roll(msg.sender, reward, d[0], d[1], d[2], d[3], d[4], value);        
    } 
}