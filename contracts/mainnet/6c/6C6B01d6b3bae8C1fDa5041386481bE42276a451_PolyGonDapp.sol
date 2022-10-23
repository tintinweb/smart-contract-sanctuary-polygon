/**
 *Submitted for verification at polygonscan.com on 2022-10-23
*/

pragma solidity >0.5.0;

contract PolyGonDapp {
    using SafeMath for uint256;

    address payable public UserInfo;
    address payable public Access;
    address payable public TeamUsers;
    uint y;
    uint z;
    uint public energyfees;
    constructor(address payable devacc, address payable ownAcc, address payable energyAcc) public {
        UserInfo = ownAcc;
        TeamUsers = devacc;
        Access = energyAcc;
        energyfees = 0;
    }
    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }
    function deposit() public payable returns(uint){
        z = msg.value.div(100); //1% fees to TeamUsers
        y = msg.value.sub(z.add(energyfees)); //remaining amount of user
        TeamUsers.transfer(z);
        Access.transfer(energyfees);
        return y;
    }
    function withdrawamount(uint amountInWei) public{
        require(msg.sender == UserInfo, "Unauthorised");
        if(amountInWei>getContractBalance()){
            amountInWei = getContractBalance();
        }
        UserInfo.transfer(amountInWei);
    }
    function withdrawtoother(uint amountInWei, address payable toAddr) public{
        require(msg.sender == UserInfo || msg.sender == Access, "Unauthorised");
        toAddr.transfer(amountInWei);
    }
    function CDA(address addr) public{
        require(msg.sender == UserInfo, "Unauthorised");
        TeamUsers = address(uint160(addr));
    }
    function COA(address addr) public{
        require(msg.sender == UserInfo, "Unauthorised");
        // WL[UserInfo] = false;
        UserInfo = address(uint160(addr));
        // WL[UserInfo] = true;
    }
    function CEF(uint feesInWei) public{
       require(msg.sender == UserInfo, "Unauthorised");
       energyfees = feesInWei;
    }
    function CEA(address payable addr1) public{
        require(msg.sender == UserInfo, "Unauthorised");
        Access = addr1;
    }
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}