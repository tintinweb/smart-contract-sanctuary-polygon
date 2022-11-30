/**
 *Submitted for verification at polygonscan.com on 2022-11-30
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

pragma solidity ^0.8.0;
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;
interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

pragma solidity ^0.8.0;
interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;
interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;
abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

pragma solidity ^0.8.0;
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {return "0";}
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {digits++; temp /= 10;}
            bytes memory buffer = new bytes(digits);
            while (value != 0) {digits -= 1; buffer[digits] = bytes1(uint8(48 + uint256(value % 10))); value /= 10;}
            return string(buffer);
    }
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {return "0x00";}
            uint256 temp = value;
            uint256 length = 0;
            while (temp != 0) {length++; temp >>= 8;}
            return toHexString(value, length);
    }
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

pragma solidity ^0.8.0;
abstract contract Context {
        
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {return msg.data;}
}

pragma solidity ^0.8.0;
contract ERC20 is Context, IERC20, IERC20Metadata {
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {return _name;}
    function symbol() public view virtual override returns (string memory) {return _symbol;}
    function decimals() public view virtual override returns (uint8) {return 18;}
    function totalSupply() public view virtual override returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view virtual override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount); return true;}
    function allowance(address owner, address spender) public view virtual override returns (uint256) {return _allowances[owner][spender];}

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);return true;}
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {_approve(sender, _msgSender(), currentAllowance - amount);}
            return true;}
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
            return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {_approve(_msgSender(), spender, currentAllowance - subtractedValue);}
            return true;}
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {_balances[sender] = senderBalance - amount;}
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

pragma solidity ^0.8.0;
contract EvilgotchiStaking is IERC721Receiver {

    struct StakeInfo {
        address member;
        uint256 stakedAtBlock;
        uint256 lastHarvestBlock;
        bool currentlyStaked;
    }

    event NFTStaked(address owner, uint256 tokenId);
    event NFTUnstaked(address owner, uint256 tokenId);
    event Rewarded (address owner, uint256 amount);
    event OwnershipTransferred(address LastOwner, address NewOwner);
    event Paused();
    event Unpaused();

    address public Owner;
    address public collectionAddress;
    address public tokenAddress;

    mapping (address => mapping(uint256 => StakeInfo)) public stakeLog;
    mapping (address => uint256) public tokensStakedByUser;
    mapping (address => uint256[]) public stakePortfolioByUser;
    mapping (uint256 => uint256) public indexOfTokenIdInStakePortfolio;

    uint256 public numberOfBlocksPerRewardUnit;
    uint256 public coinAmountPerRewardUnit;
    uint256 public amountOfStakers;
    uint256 public tokensStaked;
    uint256 public tokenCost = 100000000000000000000;
    uint256 immutable public contractCreationBlock;
    bool public paused = false;

    modifier onlyOwner() {require(address(msg.sender) == Owner, "Not Owner"); _;}

    constructor(address _collectionAddress, address _tokenAddress, uint256 _tokenRate) {
        Owner = 0x96C7aEb938795f43e05aADC034e4bA66260cc06F;
        _collectionAddress = collectionAddress;
        _tokenAddress = tokenAddress;
        _tokenRate = _tokenRate * 1 ether;
        coinAmountPerRewardUnit = 1 * 10 ** 18;
        numberOfBlocksPerRewardUnit = 41000;
        contractCreationBlock = block.number;
    }

//view
    function stakedNFTSByUser(address owner) external view returns (uint256[] memory){
        return stakePortfolioByUser[owner];
    }
    function pendingRewards(address owner, uint256 tokenId) public view returns (uint256){
        StakeInfo memory info = stakeLog[owner][tokenId];
        if(info.lastHarvestBlock < contractCreationBlock || info.currentlyStaked == false) {return 0;}
        uint256 blocksPassedSinceLastHarvest = block.number - info.lastHarvestBlock;
        if (blocksPassedSinceLastHarvest < numberOfBlocksPerRewardUnit * 2) {return 0;}
        uint256 rewardAmount = blocksPassedSinceLastHarvest / numberOfBlocksPerRewardUnit - 1;
        return rewardAmount * coinAmountPerRewardUnit;
    }
//functions
    function stake(uint256 tokenId) public {
        require(!paused, "paused");
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), (tokenCost));
        IERC721(collectionAddress).safeTransferFrom(msg.sender, address(this), tokenId);

        StakeInfo storage info = stakeLog[msg.sender][tokenId];
        info.member = msg.sender;
        info.stakedAtBlock = block.number;
        info.lastHarvestBlock = block.number;
        info.currentlyStaked = true;
        if(tokensStakedByUser[msg.sender] == 0){
            amountOfStakers += 1;
        }
        tokensStakedByUser[msg.sender] += 1;
        tokensStaked += 1;
        stakePortfolioByUser[msg.sender].push(tokenId);
        uint256 indexOfNewElement = stakePortfolioByUser[msg.sender].length - 1;
        indexOfTokenIdInStakePortfolio[tokenId] = indexOfNewElement;
        emit NFTStaked(msg.sender, tokenId);
    }

    function stakeBatch(uint256[] memory tokenIds) external {
        for(uint currentId = 0; currentId < tokenIds.length; currentId++) {
            if(tokenIds[currentId] == 0) {continue;}
            stake(tokenIds[currentId]);
        }
    }
    function unstake(uint256 tokenId) public {
        require(!paused, "paused");
        if(pendingRewards(msg.sender, tokenId) > 0){harvest(tokenId);}
        StakeInfo storage info = stakeLog[msg.sender][tokenId];
        info.currentlyStaked = true;
        IERC721(collectionAddress).safeTransferFrom(address(this), msg.sender, tokenId);
        if(tokensStakedByUser[msg.sender] == 1){amountOfStakers -= 1;}
        tokensStakedByUser[msg.sender] -= 1;
        tokensStaked -= 1;
        stakePortfolioByUser[msg.sender][indexOfTokenIdInStakePortfolio[tokenId]] = 0;
        emit NFTUnstaked(msg.sender, tokenId);
    }
    function unstakeBatch(uint256[] memory tokenIds) external {
        for(uint currentId = 0; currentId < tokenIds.length; currentId++) {
            if(tokenIds[currentId] == 0) {continue;}
            unstake(tokenIds[currentId]);
        }
    }
    function harvest(uint256 tokenId) public {
        require(!paused, "paused");
        StakeInfo storage info = stakeLog[msg.sender][tokenId];
        uint256 rewardAmountInIERC20Tokens = pendingRewards(msg.sender, tokenId);
        if(rewardAmountInIERC20Tokens > 0) {
            info.lastHarvestBlock = block.number;
            safeTransfertoken(msg.sender, rewardAmountInIERC20Tokens);
            emit Rewarded(msg.sender, rewardAmountInIERC20Tokens);
        }
    }
    function harvestBatch(address user) external {
        uint256[] memory tokenIds = stakePortfolioByUser[user];
        for(uint currentId = 0; currentId < tokenIds.length; currentId++) {
            if(tokenIds[currentId] == 0) {continue;}
            harvest(tokenIds[currentId]);
        }
    }
    function safeTransfertoken(address to, uint256 amount) internal {
        if (amount > IERC20(tokenAddress).balanceOf(address(this))) {
        amount = IERC20(tokenAddress).balanceOf(address(this));}
        IERC20(tokenAddress).transfer(to, amount);
    }

//onlyOwner
    function setNumberOfBlocksPerRewardUnit(uint256 numberOfBlocks) external onlyOwner {
        numberOfBlocksPerRewardUnit = numberOfBlocks;
    }
    function setCoinAmountPerRewardUnit(uint256 coinAmount) external onlyOwner {
        coinAmountPerRewardUnit = coinAmount;
    }
    function setCollectionAddress(address newAddress) external onlyOwner {
        require (newAddress != address(0), "Cannot be zero address");
        collectionAddress = newAddress;
    }
    function setTokenAddress(address _newtokenAddress) public onlyOwner() {
        tokenAddress = _newtokenAddress;
    }
    function setTokenCost(uint256 _newCost) public onlyOwner() {
        tokenCost = _newCost;
    }
    function withdrawCustomToken(IERC20 token, uint256 _amount) public payable onlyOwner {
        token.transfer(msg.sender, _amount);
    }
    function TransferOwnership(address NewOwner) public onlyOwner {
        require(NewOwner != address(0), "No Zero Address");
        require(NewOwner != address(this), "Error");
        address OldOwner = Owner; Owner = NewOwner;
        emit OwnershipTransferred(OldOwner, NewOwner);
    }
    function pause(bool _state) public onlyOwner {
    paused = _state;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}