/**
 *Submitted for verification at polygonscan.com on 2023-03-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);}
contract Ownable {
    address[] public admins;

    constructor()  {
        // Add some addresses to the array of admins
        admins.push(msg.sender);
    }
    modifier onlyAdmin{
        bool isAdmin = false;
        for (uint i = 0; i < admins.length; i++) {
            if (admins[i] == msg.sender) {
                isAdmin = true;
                break;
            }
        }
        require(isAdmin, "Only admins can perform this action.");
        _;
    }
    function addAdmin(address _addr)public onlyAdmin{
        admins.push(_addr);
    }
    function removeAdmin(address _addr) public onlyAdmin{
        // Remove the given address from the array of admins
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == _addr) {
                // Shift the elements of the array to the left to fill the gap
                for (uint256 j = i; j < admins.length - 1; j++) {
                    admins[j] = admins[j + 1];
                }
                // Decrease the length of the array by 1
                admins.pop();
                break;
            }
        }
    }
    function showAdmin()public view returns(address[] memory){
        return admins;
    }
 }

contract DistributeToken{
    uint public length;
    address admin;
    uint count;
    IERC20 cguToken;
    IERC20 USDT;
    constructor (address _cguToken ,address _USDT){
        // declare admin and set token address 0x003A37f1aFcb3036DeAEFC129e4B75D6ed799E73
        //0x003A37f1aFcb3036DeAEFC129e4B75D6ed799E73
        //0xb870318Bca4f5903895bF30743B11EE0fF78AA2d
        admin=msg.sender;
        cguToken=IERC20(_cguToken);
        USDT=IERC20(_USDT);
        
    }
    modifier onlyAdmin(){
        require(msg.sender==admin);
        _;
    }
    struct Player{
        uint rank;
        address playeraddress;
        uint cguToken;
        uint USDT;
    }
    mapping (uint=>Player) Splayer;


    function addPlayer(address[] memory  _address,uint[] memory cguBalance,uint[] memory USDTBalance)public onlyAdmin{
        require(_address.length == cguBalance.length);
        for(uint i=0;i<_address.length;i++){
            Splayer[i].playeraddress=_address[i];
            Splayer[i].cguToken= cguBalance[i];
            Splayer[i].USDT= USDTBalance[i];
            Splayer[i].rank=i+1;
        }length=_address.length;
        // add players to the list
        // require(count<10);
        // count++;  
        // Splayer[count].rank=count;
        // Splayer[count].playeraddress=_address;
        // Splayer[count].amount= (50/Splayer[1].rank)*10**18;
        // topPlayer[count] = _address;
        
    }
        function deletePlayer() public onlyAdmin{
        uint i=0;
        while(i<=10){
            Splayer[i]=Player(0,address(0),0,0);
              i++;
        }
        count=0;
        }
       function transferCguReward() public payable  onlyAdmin{

        require(length>0);
            for (uint i=0;i<length;i++){
                require(Splayer[i].playeraddress != address(0) ,"Add all the Address");
                require(cguToken.transfer(Splayer[i].playeraddress, Splayer[i].cguToken*10**18), "Transfer failed."); 
                Splayer[i].playeraddress=address(0);
            }   
            transferUSDTRewad();
            length=0;
            deletePlayer();
            
         }
        function transferUSDTRewad() public payable  onlyAdmin{

        require(length>0);
            for (uint i=0;i<length;i++){
                require(Splayer[i].playeraddress != address(0) ,"Add all the Address");
                require(cguToken.transfer(Splayer[i].playeraddress, Splayer[i].USDT*10**18), "Transfer failed."); 
                Splayer[i].playeraddress=address(0);
            }   
            length=0;
            deletePlayer();
         }
    function transferCguToken(address recipient, uint256 _amount) public onlyAdmin{
        cguToken.transfer(recipient,_amount);
    }
    function balanceOfCguToken() external view returns (uint256){
        return cguToken.balanceOf(address(this))/10**18;
    }
    function transferUSDT(address recipient, uint256 _amount) public onlyAdmin{
        USDT.transfer(recipient,_amount);
    }
    function balanceOfUSDT() external view returns (uint256){
        return USDT.balanceOf(address(this))/10**18;
    }
    function getPlayer(uint index)public view returns(uint rank,address playeraddress,uint _cguAmount,uint USDTAmount ){
        index=index-1;
    (rank,playeraddress,_cguAmount,USDTAmount)=(Splayer[index].rank,Splayer[index].playeraddress,Splayer[index].cguToken,Splayer[index].USDT);
    }

}