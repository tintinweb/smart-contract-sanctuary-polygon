/**
 *Submitted for verification at polygonscan.com on 2022-05-18
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: Fractionlesscontracts/NFTRegistry.sol

pragma solidity ^0.8.12;


interface FractionNFT {
    function mint(string calldata metaURI) external payable;
}

contract NFTRegistry {
    address[] public NFT;
    error Taken(string);
     address public immutable owner = msg.sender;

    function addNFTWatch(address _nftaddress) external {
        require(msg.sender == owner);
        NFT.push(_nftaddress);
    }

    function removeNFTWatch() external {
        require(msg.sender == owner);
        NFT.pop();
    }

    struct NFTdetails {
        string name;
        string ensName;
        string udName;
        string TwitterSocial;
        string github;
    }

    mapping(address => NFTdetails) details;

    string[] private chosennames;

    function setName(string calldata _name, string calldata _metadata)
        public
        payable
    {
        uint256 length = chosennames.length;
        for (uint256 i = 0; i < length; ++i) {
            if (
                keccak256(abi.encode(chosennames[i])) ==
                keccak256(abi.encode(_name))
            ) {
                revert Taken("Name already choosen");
            }
        }
        FractionNFT(NFT[0]).mint{value: msg.value}(_metadata);
        chosennames.push(_name);
        details[msg.sender].name = _name;
        (bool success,) =  payable(address(this)).call{value:msg.value}("");
        require(success,"Tranfer Failed");
    }

    function setEnsName(string calldata _ensname) public {
      //  require(bytes(_ensname).length > 2, "Name too short");
      //  string memory name = getName(msg.sender);
     //   require(bytes(name).length > 2, "Name too short");
        details[msg.sender].ensName = _ensname;
    }

    function setUdName(string calldata _nftname) public {
      //  require(bytes(_nftname).length > 2, "Name too short");
      //  string memory name = getName(msg.sender);
      //  require(bytes(name).length > 2, "Name too short");
        details[msg.sender].udName = _nftname;
    }

    function setTwitterSocial(string calldata _twitter) public {
      //  require(bytes(_twitter).length > 5, "Name too short");
        //string memory name = getName(msg.sender);
        //require(bytes(name).length > 2, "Name too short");
        details[msg.sender].TwitterSocial = _twitter;
    }

    function setGithub(string calldata _github) public {
      //  require(bytes(_github).length > 4, "Name too short");
        //string memory name = getName(msg.sender);
      //  require(bytes(name).length > 2, "Name too short");
        details[msg.sender].github = _github;
    }

    function getName(address _address) public view returns (string memory) {
        string memory tempname = details[_address].name;
        if (bytes(tempname).length > 2) {
            return details[_address].name;
        } else {
            return "";
        }
    }

    function getEnsName(address _address) public view returns (string memory) {
        string memory tempname = details[_address].ensName;
        if (bytes(tempname).length > 2) {
            return details[_address].name;
        } else {
            return "";
        }
    }

    function getUdName(address _address) public view returns (string memory) {
        string memory tempname = details[_address].udName;
        if (bytes(tempname).length > 2) {
            return details[_address].name;
        } else {
            return "";
        }
    }

    function getTwitterSocail(address _address)
        public
        view
        returns (string memory)
    {
        string memory tempname = details[_address].TwitterSocial;
        if (bytes(tempname).length > 2) {
            return details[_address].TwitterSocial;
        } else {
            return "";
        }
    }

    function getGithub(address _address) public view returns (string memory) {
        string memory tempname = details[_address].github;
        if (bytes(tempname).length > 2) {
            return details[_address].github;
        } else {
            return "";
        }
    }


    fallback () external payable{}
    receive () external payable{}
}