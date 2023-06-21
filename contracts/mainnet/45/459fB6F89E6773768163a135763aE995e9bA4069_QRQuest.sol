/**
 *Submitted for verification at polygonscan.com on 2023-06-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Math {

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

}

library Strings {

    bytes16 private constant _SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

}

interface IDemoServiceContract {
	function mintNfticket(string calldata URI, address user) external returns(uint256);
}

contract QRQuest is Ownable {

	using Strings for uint256;

	string public baseURI;

	uint256 constant TOKEN_COUNT = 8;
    uint256 constant LEADERBOARD_SIZE = 10;

	mapping(address => uint256) public ownership;
	mapping(uint256 => address) public token2wallet;
	mapping(uint256 => uint256) public tokenIdMap; // NFTicket ID to local token ID

	mapping(address => mapping(uint256 => bool)) public isRegistered;
	mapping(address => uint256[]) public regs;

    struct LeaderboardEntry {
        address wallet;
        uint256 score;
    }

    mapping(uint256 => LeaderboardEntry) leaderboard;

	IDemoServiceContract public DemoServiceContract;

    // uint256 minted_tokens;

	constructor(
		string memory _initBaseURI,
		IDemoServiceContract demo_contract_addr
	) Ownable() {
		setBaseURI(_initBaseURI);
		setDemoServiceContractAddr(demo_contract_addr);
	}


	// public

	function mint() external {

		require(ownership[msg.sender] == 0, 'already minted');

		uint256 rand_local_id = 1; // (block.prevrandao % TOKEN_COUNT) + 1; // random token ID in range [1..TOKEN_COUNT]
		string memory uri = string(abi.encodePacked(baseURI, rand_local_id.toString(), '.json'));

		uint256 ticketID = DemoServiceContract.mintNfticket(uri, msg.sender);
        // uint256 ticketID = ++minted_tokens;
		ownership[msg.sender] = ticketID;
		token2wallet[ticketID] = msg.sender;
		tokenIdMap[ticketID] = rand_local_id;

	}

	function register(uint256 id) external { // register an attendance
		require(id > 0);
		require(!isRegistered[msg.sender][id], 'already registered');
		isRegistered[msg.sender][id] = true;
		regs[msg.sender].push(id);
        addToLeaderboard(msg.sender);
	}

	function getAllRegs(address wallet) external view returns (uint256[] memory) {
		return regs[wallet];
	}

    function getLeaderboard() external view returns (LeaderboardEntry[LEADERBOARD_SIZE] memory ret) {
        for (uint256 i = 0; i < LEADERBOARD_SIZE; i++) {
            ret[i] = leaderboard[i];
        }
    }

	function tokenURI(uint256 tokenID) public view virtual returns (string memory) {
		require(tokenIdMap[tokenID] > 0, 'URI query for nonexistent token');
		uint256 local_token_id = tokenIdMap[tokenID];
		uint256 lvl = level(token2wallet[tokenID]);
		string memory level_suffix = '';
		if (lvl > 0) {
			level_suffix = string(abi.encodePacked('-', lvl.toString()));
		}
		return string(abi.encodePacked(baseURI, local_token_id.toString(), level_suffix, '.json'));
	}

	function level(address wallet) public view returns (uint256) {
		uint256 reg_count = regs[wallet].length;
		if (reg_count < 3) return 1;
		else if (reg_count < 6) return 2;
		else return 3;
	}


    // private

    function addToLeaderboard(address wallet) private {

        uint256 score = regs[wallet].length;

        if (leaderboard[LEADERBOARD_SIZE - 1].score >= score) return;

        // first pass: remove the wallet from the leaderboard to eliminate dups
        for (uint256 i = 0; i < LEADERBOARD_SIZE; i++) {
            if (leaderboard[i].wallet == wallet) {

                // shift leaderboard up
                for (uint256 j = i; j < LEADERBOARD_SIZE; j++) {
                    leaderboard[j] = leaderboard[j+1];
                }

                break;

            }
        }

        // second pass: add the wallet to the leaderboard
        for (uint256 i = 0; i < LEADERBOARD_SIZE; i++) {
            if (leaderboard[i].score < score) {

                // shift leaderboard down
                LeaderboardEntry memory curr = leaderboard[i];
                for (uint256 j = i; j < LEADERBOARD_SIZE; j++) {
                    LeaderboardEntry memory next = leaderboard[j+1];
                    leaderboard[j+1] = curr;
                    curr = next;
                }

                leaderboard[i] = LeaderboardEntry(wallet, score);
                delete leaderboard[LEADERBOARD_SIZE];

                break;

            }
        }

    }


	// only owner

	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	function setDemoServiceContractAddr(IDemoServiceContract addr) public onlyOwner {
		DemoServiceContract = addr;
	}

    function withdraw() external payable onlyOwner {
		(bool success, ) = payable(owner()).call{value: address(this).balance}('');
		require(success);
	}

}