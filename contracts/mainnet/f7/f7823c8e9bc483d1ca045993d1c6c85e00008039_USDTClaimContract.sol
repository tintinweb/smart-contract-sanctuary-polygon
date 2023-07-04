// SPDX-License-Identifier: MIT

/*

$$\   $$\ $$$$$$\ $$\   $$\ $$$$$$$$\        $$$$$$\  $$\        $$$$$$\  $$$$$$\ $$\      $$\ 
$$ |  $$ |\_$$  _|$$$\  $$ |\__$$  __|      $$  __$$\ $$ |      $$  __$$\ \_$$  _|$$$\    $$$ |
$$ |  $$ |  $$ |  $$$$\ $$ |   $$ |         $$ /  \__|$$ |      $$ /  $$ |  $$ |  $$$$\  $$$$ |
$$$$$$$$ |  $$ |  $$ $$\$$ |   $$ |         $$ |      $$ |      $$$$$$$$ |  $$ |  $$\$$\$$ $$ |
\_____$$ |  $$ |  $$ \$$$$ |   $$ |         $$ |      $$ |      $$  __$$ |  $$ |  $$ \$$$  $$ |
      $$ |  $$ |  $$ |\$$$ |   $$ |         $$ |  $$\ $$ |      $$ |  $$ |  $$ |  $$ |\$  /$$ |
      $$ |$$$$$$\ $$ | \$$ |   $$ |         \$$$$$$  |$$$$$$$$\ $$ |  $$ |$$$$$$\ $$ | \_/ $$ |
      \__|\______|\__|  \__|   \__|          \______/ \________|\__|  \__|\______|\__|     \__|

Developer: giudev.eth

*/                                                                                                                                                                                  
                                                                                               
pragma solidity ^0.8.0;

import "./interface.sol";
import "./contract.sol";

contract USDTClaimContract is Ownable, ReentrancyGuard {
    
    mapping(address => uint256) public claimableAmounts;
    IERC20 public usdtToken;
    uint256 public totalUSDT;
    uint256 public claimedUSDT;

    constructor(address _usdtTokenAddress) {
        usdtToken = IERC20(_usdtTokenAddress);}

    function batchSetClaimableAmounts(address[] calldata addresses, uint256[] calldata amounts) external onlyOwner {
        require(addresses.length == amounts.length, "Invalid input lengths");

        for (uint256 i = 0; i < addresses.length; i++) {
            claimableAmounts[addresses[i]] = amounts[i];
            totalUSDT += amounts[i];}}

    function claim() external nonReentrant {
        require(claimableAmounts[msg.sender] > 0, "No claimable amount");

        uint256 amount = claimableAmounts[msg.sender];
        claimedUSDT += amount;
        claimableAmounts[msg.sender] = 0;

        bool transferSuccess = usdtToken.transfer(msg.sender, amount);
        if (!transferSuccess) {
            claimableAmounts[msg.sender] = amount;
            claimedUSDT -= amount;}}

    function contractBalance() public view returns (uint256){
        uint256 balanceUSDT = usdtToken.balanceOf(address(this));
        return balanceUSDT;}

    function claimForAddress(address _addr) external onlyOwner nonReentrant {
        require(claimableAmounts[_addr] > 0, "No claimable amount");

        uint256 amount = claimableAmounts[_addr];
        claimedUSDT += amount;
        claimableAmounts[_addr] = 0;

        bool transferSuccess = usdtToken.transfer(_addr, amount);
        if (!transferSuccess) {
            claimableAmounts[_addr] = amount;
            claimedUSDT -= amount;}}

    receive() external payable {}

    fallback() external payable {}

    function transferERC20(address _tokenAddr, address _to, uint _amount) public onlyOwner nonReentrant {  
        require(new_type_IERC20(_tokenAddr).transfer(_to, _amount), "Could not transfer out tokens!");}

    function transferERC20O(address _tokenAddr, address _to, uint _amount) public onlyOwner nonReentrant {    
        old_type_IERC20(_tokenAddr).transfer(_to, _amount);}
        
    function withdrawEther(address _to) public onlyOwner nonReentrant {
        (bool os, ) = payable(_to).call{value: address(this).balance}('');
        require(os);}}