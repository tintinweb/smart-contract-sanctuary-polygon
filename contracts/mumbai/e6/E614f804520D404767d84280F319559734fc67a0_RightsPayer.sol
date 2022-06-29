/**
 *Submitted for verification at polygonscan.com on 2022-06-28
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract RightsPayer {
    uint256 public payPerPlay;
    uint256 public usdPerPlay;
    address payable public owner;
    address payable public receiver;

    mapping(address => bool) public isAdmin;

    event RightsPayed(
        uint256 paid,
        uint256 payPerPlay,
        uint256 plays,
        address receiver,
        address triggeredBy
    );

    error WithdrawalFailed();
    error PayRightsFailed();
    error NotAnAdmin();

    constructor(
        uint256 _payPerPlay,
        address payable _receiver,
        address _admin
    ) {
        payPerPlay = _payPerPlay;
        receiver = _receiver;
        isAdmin[_admin] = true;
        owner = payable(msg.sender);
        isAdmin[owner] = true;
    }

    modifier onlyAdmin() {
        if (msg.sender != owner && !isAdmin[msg.sender]) revert NotAnAdmin();
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getTotalPay(uint256 plays) public view returns (uint256) {
        return plays * payPerPlay;
    }

    function setPayPerPlay(uint256 newPrice) public onlyAdmin {
        payPerPlay = newPrice;
    }

    function setUsdPerPlay(uint256 newPrice) public onlyAdmin {
        usdPerPlay = newPrice;
    }

    function setReceiver(address payable _receiver) public onlyAdmin {
        receiver = _receiver;
    }

    function addAdmin(address _admin) external onlyOwner {
        isAdmin[_admin] = true;
    }

    function deleteAdmin(address _admin) external onlyOwner {
        delete isAdmin[_admin];
    }

    function setOwner(address payable _owner) external onlyOwner {
        owner = _owner;
    }

    function payRightsInMatic(uint256 plays) public onlyAdmin {
        uint256 total = plays * payPerPlay;

        (bool success, ) = receiver.call{value: total}("");
        if (!success) revert PayRightsFailed();
        emit RightsPayed(total, payPerPlay, plays, receiver, msg.sender);
    }

    function payRightsInUSDT(uint256 plays) public onlyAdmin {
        IERC20 usdt = IERC20(
            address(0xdAC17F958D2ee523a2206206994597C13D831ec7)
        );
        uint256 total = usdPerPlay * plays;
        // transfers USDT that belong to your contract to the specified address
        usdt.transfer(receiver, total);
    }

    function payTokenInERC20(address erc_contract, uint256 coins)
        public
        onlyAdmin
    {
        IERC20 erc20 = IERC20(address(erc_contract));
        erc20.transfer(receiver, coins);
    }

    // withdraw matic to owner
    function withdraw() external onlyOwner {
        (bool success, ) = owner.call{value: address(this).balance}("");
        if (!success) revert WithdrawalFailed();
    }

    function withdrawErc(address erc_contract) external onlyOwner {
        IERC20 erc20 = IERC20(address(erc_contract));
        erc20.transfer(receiver, erc20.balanceOf(address(this)));
    }

    function fundContract() external payable {}

    receive() external payable {}
}