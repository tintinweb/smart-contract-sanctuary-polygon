/**
 *Submitted for verification at polygonscan.com on 2022-03-21
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IOwnable {
    function manager() external view returns (address);

    function renounceManagement() external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;
}

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed(address(0), _owner);
    }

    function manager() public view override returns (address) {
        return _owner;
    }

    modifier onlyManager() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceManagement() public virtual override onlyManager() {
        emit OwnershipPushed(_owner, address(0));
        _owner = address(0);
    }

    function pushManagement(address newOwner_) public virtual override onlyManager() {
        require(newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


interface ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface NFT {
    function mint(uint index) external;
    function transferOwnership(address newOwner) external;
    function totalSupply() external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function setRewardAmount(uint index, uint256 _rewardAmount) external;
    function setStakeCost(uint index, uint256 _stakingCost) external;
    function setCost(uint index, uint _newCost) external;
    function setName(uint index, string calldata _name) external;
    function setAvailable(uint index, bool _available) external;
    function setBaseExtension(uint index, string calldata _baseExtension) external;
    function setBaseURI(string memory _newBaseURI) external;
    function pause(bool _state) external;
    function addNewNFTType(uint _cost, string calldata _name, uint256 _rewardAmount, uint256 _stakingCost, bool _available, string calldata _baseExtension) external returns (uint);
}

interface IUniswapV2Pair {
  event Sync(uint112 reserve0, uint112 reserve1);
  function sync() external;
}

contract Minter is Ownable, IERC721Receiver  {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    address public nftAddress;
    address public stableCoinAdress;
    address public dominiumAddress;
    address public treasuryAddress;
    address public liquidityAddress;

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "Queue Locked");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    address private shutoffAddress;
    bool public shutoff;

    uint256 cost5_usdc = 130000000; // Zeno
    uint256 cost5_dom = 22000000000; // Zeno
    uint256 cost6_usdc = 1300000000; // Herodotus
    uint256 cost6_dom = 2200000000000; // Herodotus
    uint256 cost7_usdc = 13000000000; // Homer
    uint256 cost7_dom = 220000000000; // Homer

    constructor() {
        nftAddress = 0xa04A030f4C8b22B11E98e1CbaF280e0fF01fED79; // address of nft.sol
        stableCoinAdress = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        dominiumAddress = 0x0e2c818FEa38E7df50410F772b7d59aF20589A62;
        treasuryAddress = 0x0000000000000000000000000000000000000000;
        liquidityAddress = 0x0000000000000000000000000000000000000000;
        shutoffAddress = msg.sender;
    }

    function nftCosts(bool stable, uint _index) view public returns (uint256) {
        if (stable) {
            if (_index == 5) {
                return cost5_usdc;
            } else if (_index == 6) {
                return cost6_usdc;
            } else if (_index == 7) {
                return cost7_usdc;
            } else {
                return 0;
            }
        } else {
             if (_index == 5) {
                return cost5_dom;
            } else if (_index == 6) {
                return cost6_dom;
            } else if (_index == 7) {
                return cost7_dom;
            } else {
                return 0;
            }   
        }
    }

    function mintDOM(uint _index) public lock {
        require(!shutoff, "Minting on pause");
        require(_index >= 5 && _index <= 7, "Trying to mint wrong index");

        uint256 cost = nftCosts(false, _index);
        if (cost == 0) {
            return;
        }
        IERC20(dominiumAddress).transferFrom(msg.sender, address(this), cost);
        IERC20(dominiumAddress).transfer(treasuryAddress, cost);

        NFT(nftAddress).mint(_index);
        uint256 tokenID = NFT(nftAddress).totalSupply();
        NFT(nftAddress).safeTransferFrom(address(this), msg.sender, tokenID);
    }

    function mintUSDC(uint _index) public lock {
        require(!shutoff, "Minting on pause");
        require(_index >= 5 && _index <= 7, "Trying to mint wrong index");

        uint256 cost = nftCosts(true, _index);
        if (cost == 0) {
            return;
        }

        IERC20(stableCoinAdress).transferFrom(msg.sender, address(this), cost);
        IERC20(stableCoinAdress).transfer(treasuryAddress, cost.div(100).mul(70));
        IERC20(stableCoinAdress).transfer(liquidityAddress, cost.div(100).mul(30));

        IUniswapV2Pair(liquidityAddress).sync();

        NFT(nftAddress).mint(_index);
        uint256 tokenID = NFT(nftAddress).totalSupply();
        NFT(nftAddress).safeTransferFrom(address(this), msg.sender, tokenID);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function emergencyToggle() public {
        require(msg.sender == shutoffAddress, "Not the shut off address");
        shutoff = !shutoff;
    }

    function transferShutoffAddress(address _address) public {
        require(msg.sender == shutoffAddress, "Not the shut off address");
        shutoffAddress = _address;
    }

    function emergencyWithdrawNFT(uint256 _tokenID) public onlyManager {
        NFT(nftAddress).safeTransferFrom(address(this), msg.sender, _tokenID);
    }

    function emergencyWithdrawToken(address _address, uint256 amount) public onlyManager {
        IERC20(_address).transfer(msg.sender, amount);
    }

    function setDomCost(uint _index, uint256 _amount) public onlyManager {
        if (_index == 5) {
            cost5_dom = _amount;
        } else if (_index == 6) {
            cost6_dom = _amount;
        } else if (_index == 7) {
            cost7_dom = _amount;
        }    
    }
    
    function setUSDCCost(uint _index, uint256 _amount) public onlyManager {
        if (_index == 5) {
            cost5_usdc = _amount;
        } else if (_index == 6) {
            cost6_usdc = _amount;
        } else if (_index == 7) {
            cost7_usdc = _amount;
        }    
    }

    // NFT Proxy Functions
    function transferNFTOwnership(address _address) public onlyManager {
        NFT(nftAddress).transferOwnership(_address);
    }

    function setRewardAmount(uint index, uint256 _rewardAmount) public onlyManager {
        NFT(nftAddress).setRewardAmount(index, _rewardAmount);
    }

    function setStakeCost(uint index, uint256 _stakingCost) public onlyManager {
        NFT(nftAddress).setStakeCost(index, _stakingCost);
    }

    function setCost(uint index, uint _newCost) public onlyManager {
         NFT(nftAddress).setCost(index, _newCost);
    }

    function setName(uint index, string calldata _name) public onlyManager {
         NFT(nftAddress).setName(index, _name);
    }

    function setAvailable(uint index, bool _available) public onlyManager {
         NFT(nftAddress).setAvailable(index, _available);
    }

    function setBaseExtension(uint index, string calldata _baseExtension) public onlyManager {
         NFT(nftAddress).setBaseExtension(index, _baseExtension);
    }

    function setBaseURI(string memory _newBaseURI) public onlyManager {
         NFT(nftAddress).setBaseURI(_newBaseURI);
    }

    function pause(bool _state) public onlyManager {
        NFT(nftAddress).pause(_state);
    }

    function addNewNFTType(uint _cost, string calldata _name, uint256 _rewardAmount, uint256 _stakingCost, bool _available, string calldata _baseExtension) public onlyManager returns (uint) {
        return NFT(nftAddress).addNewNFTType(_cost, _name, _rewardAmount, _stakingCost, _available, _baseExtension);
    }
}