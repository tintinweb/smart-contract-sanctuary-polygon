/**
 *Submitted for verification at polygonscan.com on 2022-04-03
*/

// File: contracts/utils/Owner.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Owner {
    bool private _contractCallable = false;
    bool private _pause = false;
    address private _owner;
    address private _pendingOwner;

    event NewOwner(address indexed owner);
    event NewPendingOwner(address indexed pendingOwner);
    event SetContractCallable(bool indexed able, address indexed owner);

    constructor() {
        _owner = msg.sender;
    }

    // ownership
    modifier onlyOwner() {
        require(owner() == msg.sender, "caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    function setPendingOwner(address account) public onlyOwner {
        require(account != address(0), "zero address");
        _pendingOwner = account;
        emit NewPendingOwner(_pendingOwner);
    }

    function becomeOwner() external {
        require(msg.sender == _pendingOwner, "not pending owner");
        _owner = _pendingOwner;
        _pendingOwner = address(0);
        emit NewOwner(_owner);
    }

    modifier checkPaused() {
        require(!paused(), "paused");
        _;
    }

    function paused() public view virtual returns (bool) {
        return _pause;
    }

    function setPaused(bool p) external onlyOwner {
        _pause = p;
    }

    modifier checkContractCall() {
        require(contractCallable() || notContract(msg.sender), "non contract");
        _;
    }

    function contractCallable() public view virtual returns (bool) {
        return _contractCallable;
    }

    function setContractCallable(bool able) external onlyOwner {
        _contractCallable = able;
        emit SetContractCallable(able, _owner);
    }

    function notContract(address account) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size == 0;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface INGC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function mint(address recipient_, string memory tokenURI)
        external
        returns (uint256);

    function getTokens(address owner) external view returns (uint256[] memory);

    function getNextTokenId() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IPair{
    function getReserves() external view returns(uint256, uint256, uint256);
}

contract Templar is Owner {
    struct Token {
        uint256 energy;
        uint256 energyAt;
        uint256 energyCD;
        uint256 levelCode;
        bool isStake;
        bool isSell;
    }

    struct Supply {
        uint256 fee;
        address token;
        uint256 total;
        uint256 left;
        uint256[] levelCode;
        uint256[] levelOffset;
    }

    struct AccountInfo {
        uint256 reward;
        uint256 claimAt;
        uint256 totalClaim;
        uint256 pdReward;
        uint256 ngcReward;
        bool isInvite;
        address inviter;
        address[] invitee;
    }

    bytes32 private _seed;

    INGC721 public NGC721;
    IPair public Pair;

    uint256 public RANDSEED = 10000;

    address public FeeAccount;
    address private DeadAddress =
        address(0x000000000000000000000000000000000000dEaD);

    mapping(uint256 => Token) private tokenInfo;
    mapping(address => AccountInfo) private accountInfo;
    mapping(uint256 => Supply) private supplyInfo;

    event Bind(address indexed inviter, address indexed invitee);

    event Open(
        address indexed account,
        uint256 fee,
        uint256 indexed tokenId,
        uint256 indexed levelCode,
        uint256 random
    );

    constructor(INGC721 NGC721_, IPair Pair_, address FeeAccount_) Owner() {
        NGC721 = NGC721_;
        Pair = Pair_;
        FeeAccount = FeeAccount_;
    }

    receive() external payable {}

    function setNGC721(INGC721 _NGC721) public onlyOwner returns (bool) {
        NGC721 = _NGC721;
        return true;
    }

    function setPair(IPair _pair) public onlyOwner returns (bool) {
        Pair = _pair;
        return true;
    }

    function setFeeAccount(address _feeAccount)
        public
        onlyOwner
        returns (bool)
    {
        FeeAccount = _feeAccount;
        return true;
    }

    function setSupplyInfo(
        uint256 id,
        uint256 total,
        uint256 fee,
        address token,
        uint256[] memory levelCode,
        uint256[] memory openRate
    ) public onlyOwner {
        require(levelCode.length == openRate.length, "rewrite it");
        supplyInfo[id].fee = fee;
        supplyInfo[id].total = total;
        supplyInfo[id].left = total;
        supplyInfo[id].token = token;
        supplyInfo[id].levelCode = levelCode;

        uint256 su;
        uint256[] memory offset = new uint256[](levelCode.length);
        for (uint256 i = 0; i < levelCode.length; i++) {
            su += openRate[i];
            offset[i] = su;
        }
        require(su == RANDSEED, "denominator is error");
        supplyInfo[id].levelOffset = offset;
    }

    function getSupplyInfo(uint256 id)
        external
        view
        returns (
            uint256 fee,
            uint256 total,
            uint256 left,
            address token,
            uint256[] memory levelCode,
            uint256[] memory levelOffset
        )
    {
        Supply memory info = supplyInfo[id];
        return (
            info.fee,
            info.total,
            info.left,
            info.token,
            info.levelCode,
            info.levelOffset
        );
    }

    function setParentByAdmin(address user, address parent) public onlyOwner {
        migrateAccountInfo(msg.sender);

        require(accountInfo[user].inviter == address(0), "already bind");
        accountInfo[user].inviter = parent;
        accountInfo[parent].invitee.push(user);
    }

    function bind(address inviter) external checkContractCall checkPaused {
        migrateAccountInfo(msg.sender);

        require(inviter != address(0), "not zero account");
        require(inviter != msg.sender, "can not be yourself");
        require(accountInfo[msg.sender].inviter == address(0), "already bind");
        accountInfo[msg.sender].inviter = inviter;
        accountInfo[inviter].invitee.push(msg.sender);
        emit Bind(inviter, msg.sender);
    }

    function _rand(uint256 i) public returns(uint256) {
        (uint256 r0, uint256 r1,) = Pair.getReserves();
        _seed = keccak256(abi.encodePacked(_seed, msg.sender, blockhash(block.number-1), block.timestamp+i, block.difficulty, block.coinbase, r0, r1));
        return uint256(_seed) % RANDSEED;
    }

    function multMint(uint256 nftAmount, uint256 supplyId, string[] memory tokenUrls) external checkContractCall checkPaused {
        require(nftAmount > 0, "multiple");
        require(supplyInfo[supplyId].fee != 0, "wrong supplyId");

        supplyInfo[supplyId].left -= nftAmount;
        uint256 fee = nftAmount * supplyInfo[supplyId].fee;
        IERC20 token = IERC20(supplyInfo[supplyId].token);
        address inviter = accountInfo[msg.sender].inviter;

        uint256 rate;
        if (inviter != address(0)) {
            if (!accountInfo[msg.sender].isInvite) {
                accountInfo[msg.sender].isInvite = true;
            }

            uint256 inviterFee = fee * 3 / 100;
            token.transferFrom(msg.sender, inviter, inviterFee);
            accountInfo[inviter].ngcReward += inviterFee;

            rate = 3;
        }

        uint256 feeAccountFee = fee * 2 / 100;
        token.transferFrom(msg.sender, FeeAccount, feeAccountFee);
        accountInfo[FeeAccount].ngcReward += feeAccountFee;

        rate += 2;

        token.transferFrom(msg.sender, DeadAddress, fee * (100-rate) / 100);

        for (uint256 index = 0; index < nftAmount; index++) {
            uint256 tokenId = NGC721.getNextTokenId();
            uint256 r = _rand(index);

            for (
                uint256 i = 0;
                i < supplyInfo[supplyId].levelCode.length;
                i++
            ) {
                if (r < supplyInfo[supplyId].levelOffset[i]) {
                    tokenInfo[tokenId].levelCode = supplyInfo[supplyId]
                        .levelCode[i];
                    break;
                }
            }

            NGC721.mint(
                msg.sender,
                tokenUrls[tokenInfo[tokenId].levelCode / 100 - 1]
            );
            emit Open(msg.sender, supplyInfo[supplyId].fee, tokenId, tokenInfo[tokenId].levelCode, r);
        }

    }

    function _getAccountInfo(address account)
        private
        view
        returns (uint256 reward, uint256 claimAt)
    {
        return (accountInfo[account].reward, accountInfo[account].claimAt);
    }

    function getAccountInfo(address account)
        external
        view
        returns (
            uint256 reward,
            uint256 claimAt,
            address inviter,
            address[] memory invitees
        )
    {
        AccountInfo memory info = accountInfo[account];
        if (accountInfo[account].totalClaim == 0) {
            (reward, claimAt) = _getAccountInfo(account);
            invitees = accountInfo[account].invitee;
            return (reward, claimAt, info.inviter, info.invitee);
        } else {
            return (info.reward, info.claimAt, info.inviter, info.invitee);
        }
    }

    function _getTokenInfo(uint256 tokenId) private view returns (uint256 energyAt, uint256 energy, uint256 levelCode) {
        Token memory token = tokenInfo[tokenId];
        if (token.levelCode < 700) {
            energyAt = 0;
            energy = 100;
        } else {
            uint256 r = (block.timestamp - token.energyAt) / token.energyCD;
            if (token.energy <= r) {
                energy = 0;
            } else {
                energy = token.energy - r;
            }
            energyAt = token.energyAt;    
        }

        return (energyAt, energy, token.levelCode);
    }

    function getTokenInfo(uint256 tokenId) public view returns (uint256 energy, uint256 energyAt, uint256 energyCD, uint256 levelCode, bool isStake, bool isSell) {
        Token memory token = tokenInfo[tokenId];

        (energyAt, energy, levelCode) = _getTokenInfo(tokenId);

        return (energyAt, energyAt, token.energyCD, levelCode, token.isStake, token.isSell);
        
    }

    function getInvitation(address account)
        external
        view
        returns (
            address inviter,
            uint256 pdReward,
            uint256 ngcReward,
            bool isInvite,
            address[] memory invitees
        )
    {
        AccountInfo memory info = accountInfo[account];
        return (
            info.inviter,
            info.pdReward,
            info.ngcReward,
            info.isInvite,
            info.invitee
        );
    }

    function migrateAccountInfo(address account) internal {
        if (accountInfo[account].totalClaim == 0) {
            (uint256 reward, uint256 claimAt) = _getAccountInfo(account);
            accountInfo[account].reward = reward;
            accountInfo[account].claimAt = claimAt;
            accountInfo[account].totalClaim = 1;
        }
    }

    

}