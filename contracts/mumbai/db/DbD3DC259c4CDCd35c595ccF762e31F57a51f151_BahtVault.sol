/**
 *Submitted for verification at polygonscan.com on 2022-05-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @dev Store baht amount that user deposit to Sharity.
 * Mint will increase bath amount parralle with baht in SCB Sandbox account.
 * Donate will transfer baht amount to campaign's wallet.
 * Burn will decrease baht amount in campaign's wallet they used up fiat money.
 */
contract BahtVault {

    // bytes32 public constant ADMIN = keccak256("ADMIN");
    // Mapping user's wallet address with baht amount.
    mapping (address => uint256) public BahtAmountFromAddress;

    // Event for display on frontend.
    event Mint(address indexed userAddress, uint256 amount);
    event Donate(address indexed fromAddress, address indexed toAddress, uint256 amount);
    event Burn(address indexed userAddress, uint256 amount, string reason);

    // Initial admin role setup (owner).
    // constructor() {
    //     _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    // }

    function mint(uint256 _amount) public {
        BahtAmountFromAddress[msg.sender] += _amount;
        emit Mint(msg.sender, _amount);
    }

    function donate(address _to, uint256 _amount) public {
        require(BahtAmountFromAddress[msg.sender] >= _amount, "[BahtVault.donate] Insufficient balance.");
        BahtAmountFromAddress[msg.sender] -= _amount;
        BahtAmountFromAddress[_to] += _amount;
        emit Donate(msg.sender, _to, _amount);
    }

    function burn(uint256 _amount, string memory _reason) public {
        require(BahtAmountFromAddress[msg.sender] >= _amount, "[BahtVault.burn] Insufficient balance.");
        BahtAmountFromAddress[msg.sender] -= _amount;
        emit Burn(msg.sender, _amount, _reason);
    }

    function getBalance(address _address) public view returns (uint256) {
        return BahtAmountFromAddress[_address];
    }
}