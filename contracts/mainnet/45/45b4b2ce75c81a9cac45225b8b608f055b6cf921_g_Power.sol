/**
 *Submitted for verification at polygonscan.com on 2023-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17; 

//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
contract owned
{
    address internal owner;
    address internal newOwner;
    address public signer;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
        signer = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    modifier onlySigner {
        require(msg.sender == signer, 'caller must be signer');
        _;
    }


    function changeSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}



//*******************************************************************//
//------------------         token interface        -------------------//
//*******************************************************************//

 interface tokenInterface
 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
 }



//*******************************************************************//
//------------------        MAIN contract         -------------------//
//*******************************************************************//

contract g_Power is owned {

    struct investInfo {
        uint investedAmount;
        uint lastIndex;
        uint totalWithdrawn;
        address referrer;
    }

    mapping(address => investInfo[6]) public investInfos;
    mapping(address => address) public referrer;
    address public tokenAddress;

    struct poolInfo {
        uint totalPoolAmount;
        uint totalPoolGain;
    }

    // poolIndex => poolTypeInfo
    mapping(uint => poolInfo[5]) public poolInfos;
    
    mapping(uint => poolInfo) public founderPool;
    uint public founderLastPoolIndex;

    uint[5] lastPoolIndex;

    uint[6] public poolPrice;

    constructor () {
        poolPrice[0] = 25 * ( 10 ** 18 );
        poolPrice[1] = 50 * ( 10 ** 18 );
        poolPrice[2] = 100 * ( 10 ** 18 );
        poolPrice[3] = 250 * ( 10 ** 18 );
        poolPrice[4] = 500 * ( 10 ** 18 );
        poolPrice[5] = 1000 * ( 10 ** 18 );

        referrer[owner] = owner;

        founderLastPoolIndex = 1;

        lastPoolIndex[0] = 1;
        lastPoolIndex[1] = 1;
        lastPoolIndex[2] = 1;
        lastPoolIndex[3] = 1;
        lastPoolIndex[4] = 1;

    }


    function setTokenAddress(address _tokenAddress) public onlyOwner returns(bool){
        tokenAddress = _tokenAddress;
        return true;
    }


    function register(address _referrer, uint poolType, uint quantity) public returns(bool) {
        require(referrer[msg.sender] == address(0), "please call invest");
        if (_referrer == address(0)) _referrer = owner;
        referrer[msg.sender] = _referrer;
        process(poolType,quantity,_referrer);
        return true;
    }
    
    function invest(uint poolType, uint quantity) public returns(bool) {
        require(referrer[msg.sender] != address(0), "please go for register");
        process(poolType,quantity, referrer[msg.sender]);
        return true;
    }

    function process(uint _poolType, uint _quantity, address _ref) internal returns(bool) {
        require(_poolType <= 4, "Invalid pool type");
        investInfo memory temp = investInfos[msg.sender][_poolType];

        uint lpi = lastPoolIndex[_poolType];
        if(lpi > temp.lastIndex && temp.lastIndex != 0) {
            require(withdraw(_poolType,lpi), "withdraw fail, try directly");
        }
        uint amt = poolPrice[_poolType] * _quantity;
        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), amt);
        temp.investedAmount += amt;
        temp.lastIndex = lpi;
        investInfos[msg.sender][_poolType] = temp;

        lastPoolIndex[_poolType]++;
        poolInfos[lpi+1][_poolType].totalPoolAmount = poolInfos[lpi][_poolType].totalPoolAmount + amt;
        poolInfos[lpi+1][_poolType].totalPoolGain += amt * 4/50;

        uint j =  15;
        for (uint i=1;i<5;i++) {
            lpi = lastPoolIndex[i]+1;
            poolInfos[lpi][_poolType].totalPoolAmount = poolInfos[lpi-1][_poolType].totalPoolAmount;
            poolInfos[lpi][_poolType].totalPoolGain += amt * 4/5 * j/100;
            lastPoolIndex[i]++;
            j = j + 5;
        }

        tokenInterface(tokenAddress).transfer(_ref, amt/5);

        return true;
    }

    function beFounder(uint quantity) public returns(bool) {
        require(referrer[msg.sender] != address(0), "please go for register");
        processFounder(quantity, referrer[msg.sender]);
        return true;
    }

    function processFounder(uint _quantity, address _ref) internal returns(bool) {
        uint _poolType = 5;
        investInfo memory temp = investInfos[msg.sender][_poolType];

        uint lpi = founderLastPoolIndex;
        if(lpi > temp.lastIndex && temp.lastIndex != 0) {
            require(withdrawFounder(lpi), "withdraw founder fail, try directly");
        }
        uint amt = poolPrice[_poolType] * _quantity;
        tokenInterface(tokenAddress).transferFrom(msg.sender, address(this), amt);
        temp.investedAmount += amt;
        temp.lastIndex = lpi;
        investInfos[msg.sender][_poolType] = temp;

        founderLastPoolIndex++;
        founderPool[lpi+1].totalPoolAmount = founderPool[lpi].totalPoolAmount + amt;


        uint j =  15;
        for (uint i=1;i<5;i++) {
            lpi = lastPoolIndex[i]+1;
            poolInfos[lpi][_poolType].totalPoolAmount = poolInfos[lpi-1][_poolType].totalPoolAmount;
            poolInfos[lpi][_poolType].totalPoolGain += amt * 4/5 * j/100;
            lastPoolIndex[i]++;
            j = j + 5;
        }

        tokenInterface(tokenAddress).transfer(_ref, amt/5);

        return true;
    }



    function withdraw(uint _poolType,uint upToIndex) public returns(bool) {
        uint lpi = lastPoolIndex[_poolType];
        investInfo memory temp = investInfos[msg.sender][_poolType];

        uint totalGain;

        if( temp.lastIndex < lpi && upToIndex < lpi && temp.lastIndex != 0){

                for(uint i=temp.lastIndex; i<lpi; i++) {
                    uint percnt = temp.investedAmount *  100 / poolInfos[i][_poolType].totalPoolAmount ;
                    totalGain += percnt * poolInfos[i][_poolType].totalPoolGain / 100;                   
                }

                if (temp.totalWithdrawn + (totalGain / 2) > 4 * temp.investedAmount ) totalGain = (4 * temp.investedAmount) - temp.totalWithdrawn;
                
                if(totalGain >= 10 * ( 10 ** 18)){
                    for(uint i=temp.lastIndex; i<lpi; i++) {
                        investInfos[msg.sender][_poolType].lastIndex = i;
                    }
                    tokenInterface(tokenAddress).transfer(msg.sender, totalGain/2);

                    address _ref = referrer[msg.sender];
                    for(uint j = 0; j < 10; j++ ) {
                        temp = investInfos[_ref][_poolType];
                        uint amt;
                        if (temp.totalWithdrawn + (totalGain*3/100) > 4 * temp.investedAmount ) amt = (4 * temp.investedAmount) - temp.totalWithdrawn;
 
                        if(amt > 0) tokenInterface(tokenAddress).transfer(_ref, amt);
                        else tokenInterface(tokenAddress).transfer(_ref, totalGain*3/100);
                        _ref = referrer[_ref];
                    }

                    lpi = founderLastPoolIndex;
                    
                    founderPool[lpi+1].totalPoolGain += totalGain /5;
                }


        }

        return true;
    }   


    function withdrawFounder(uint upToIndex) public returns(bool) {
        uint _poolType = 5;
        uint lpi = founderLastPoolIndex;
        investInfo memory temp = investInfos[msg.sender][_poolType];

        uint totalGain;

        if( temp.lastIndex < lpi && upToIndex < lpi && temp.lastIndex != 0){

                for(uint i=temp.lastIndex; i<lpi; i++) {
                    uint percnt = temp.investedAmount *  100 / founderPool[i].totalPoolAmount ;
                    totalGain += percnt * founderPool[i].totalPoolGain / 100;
                    investInfos[msg.sender][_poolType].lastIndex = i;                   
                }
               
                if (temp.totalWithdrawn + totalGain > 4 * temp.investedAmount ) totalGain = (4 * temp.investedAmount) - temp.totalWithdrawn;
                tokenInterface(tokenAddress).transfer(msg.sender, totalGain);

        }

        return true;
    }  


}