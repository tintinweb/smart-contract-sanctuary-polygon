// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.8.0 < 0.9.0;

contract LuckGame{
    address public owner;
    mapping(address=>bool) public bannedUses;
    mapping(address=>LuckGameDetails) public contractsList;
    uint256 public fixedAmount = 0.001 ether;

    event NewGameCreated(
    address indexed gameOwner,
    uint256 indexed amount,
    address indexed contractAddress
    );

    event RecentalyRewards(
        address indexed contractAdddr , 
        address indexed gameOwner, 
        uint256 indexed reward
    );

    struct LuckGameDetails{
        bool exist;
        address gameOwner;
        uint256 amount;
        bool rewardDistributed;
    }

    constructor(){
        owner = msg.sender;
    }

    modifier ownerRequire(){
        require(msg.sender == owner);
        _;
    }


    function changeFixedAmount(uint256 _amount) public ownerRequire{
        fixedAmount = _amount;
    }
                                                                                                                   

    function createNewGame() public payable {
        require(!bannedUses[msg.sender], "You are banned by owner");
        uint256 val = msg.value;
        address sender = msg.sender;
        require((fixedAmount <= val ), "amount must be greater than or equal to 0.001 ether");
        Game newGame = new Game();
        newGame.addData(address(newGame), val, sender);
        LuckGameDetails storage newLuckGameDetails = contractsList[address(newGame)];
        newLuckGameDetails.exist = true;
        newLuckGameDetails.gameOwner = sender;
        newLuckGameDetails.amount = val;
        emit NewGameCreated(sender, val, address(newGame));
    }

    function withdrawReward(address _contractAdddr , address _gameOwner, uint256 _amount) external payable{
        require(contractsList[_contractAdddr].exist,"something is wrong");
        require(!contractsList[_contractAdddr].rewardDistributed, "You have already got reward");
        require(contractsList[_contractAdddr].amount == _amount, "amount is wrong");
        require(contractsList[_contractAdddr].gameOwner == _gameOwner, "Game owner not exist");
        payable(contractsList[_contractAdddr].gameOwner).transfer(_amount * 2);
        contractsList[_contractAdddr].rewardDistributed = true;
        emit RecentalyRewards(_contractAdddr,_gameOwner, _amount * 2);
    }

    function banToUser(address _address) private ownerRequire{
        bannedUses[_address] = true;
    }

  function banToContract(address _address) private ownerRequire{
        contractsList[_address].exist = false;
    }

  function getBalance() public ownerRequire view returns(uint256){
        return address(this).balance;
    }

   
    function getFund(uint _value) public ownerRequire payable{
        payable(owner).transfer(_value);
    }
   

    function DepositeToContract() public ownerRequire payable {}
}


contract Game{
     address public gameOwner;
     address public contractAddress;
     uint public changes  = 5;
     uint public amount;
     uint8[9] public boxes;
     uint[] public redbox;
    bool public exist;
    bool public expired; 
    bool public winned;
    bool public amountDistributed;


    function addData(address contractAdr, uint val, address sender) external{
        gameOwner = sender;
        amount = val;
        contractAddress = contractAdr;
        boxes = random([1, 2,3, 4, 0, 1, 2,3 , 4]);
        exist = true;
    }

   
    
    function random(uint8[9] memory _myArray) private view returns(uint8[9] memory) {
        uint a = _myArray.length; 
        uint b = _myArray.length;
        for(uint i = 0; i< b ; i++){
            uint randNumber =(uint(keccak256      
            (abi.encodePacked(block.timestamp,_myArray[i]))) % a);
            uint8 interim = _myArray[randNumber];
            _myArray[randNumber]= _myArray[a-1];
            _myArray[a-1] = interim;
            a = a-1;
        }
        return _myArray;        
    }


    function openBox(uint _num) public{
        require(msg.sender == gameOwner, "You have not permitions");
        require(exist, "gameowner have not this game");
        require(!expired, "This game is expired");
        require((_num > 0 && _num < 10), "Something is wrong.");
        require(changes>0, "You have lossed, Please try again");
        uint redBoxLength = redbox.length;
        require(redBoxLength < 8, "Please check this contract Details, it is already expired");

        if(boxes[_num - 1] == 0){
            expired = true;
            winned = false;
        }else{
        if(redBoxLength>1){
            if(redBoxLength % 2 != 0){
                if(redbox[redBoxLength - 1] == boxes[_num - 1]){
                    redbox[redBoxLength] = boxes[_num - 1];
                    if(redbox.length == 8){
                        expired = true;
                        winned = true;
                    }
                }else{
                    changes--;
                    if(changes == 0){
                        expired = true;
                        winned = false;
                    }
                }
            }else{
                redbox[redBoxLength] = boxes[_num - 1];
            }
        }else{
            redbox[0] = boxes[_num - 1];
        }
       }
    }

  

    function getReward() public {
        require(msg.sender == gameOwner, "You have not permitions");
        require(exist, "gameowner have not this game");
         require(!amountDistributed, "Already amount discributed");
        require(expired, "This game is not expired");
        require(winned, "you are not winned this game");
        LuckGame lottery;
        lottery.withdrawReward(address(this), gameOwner,  amount);
        amountDistributed = true;
    }
}