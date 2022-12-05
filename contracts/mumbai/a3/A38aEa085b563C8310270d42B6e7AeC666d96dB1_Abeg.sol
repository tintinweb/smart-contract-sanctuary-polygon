// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Abeg
 * @dev Implements a giveaway platform reminiscing PocketApp(fka Abeg).
 */
contract Abeg {
    // Random Number Generation variables used for
    // choosing winners for a giveaway.
    // https://en.wikipedia.org/wiki/Linear_congruential_generator
    uint256 internal randomNumSeed;
    uint256 internal randomNumMultiplier;
    uint256 internal randomNumIncrement;
    uint256 internal randomNumModulo;

    // a counter that increments on successful creation of a giveaway.
    uint256 public giveawayIdentifierCounter;

    // address used to represent matic
    address internal constant zeroAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // an array of tokens supported apart from Ether.
    uint8 internal constant tokensLimit = 10;
    address[] internal supportedERC20Tokens;

    // the address of the contract deployer.
    address public immutable owner;

    // store of giveaway identifier to their information
    struct GiveawayDetail {
        address creator;
        string name;
        uint256 amount;
        address tokenAddress;
        uint8 numberOfWinners;
        uint64 maximumParticipants;
        uint256 createdAt;
        uint256 endAt;
        bool isSuccess;
        bool hasWinners;
    }
    mapping(uint256 => GiveawayDetail) giveaways;

    // giveaway winners
    struct GiveawayWinner {
        bool hasWithdrawnFunds;
        bool isValid;
    }
    mapping(uint256 => mapping(address => GiveawayWinner)) giveawayWinners;
    mapping(uint256 => address[]) giveawayWinnersArray;

    // store of user created giveaways
    mapping(address => uint256[]) addressesToGiveaways;

    // array of giveaways identifiers
    // this is preferable to looping from 0 -> giveawayIdentifierCounter on every call
    uint256[] giveawaysArray;

    // store of participants of giveaways
    mapping(uint256 => mapping(address => bool)) giveawaysParticipantsMapping;
    mapping(uint256 => address[]) giveawaysParticipantsArray;

    // Modifiers
    modifier isContractOwner(address addr) {
        require(addr == owner, "Only the contract owner can make this action");
        _;
    }
    modifier giveawayExists(uint256 giveawayId) {
        require(giveaways[giveawayId].isSuccess, "Giveaway does not exist");
        _;
    }

    modifier giveawayHasEnded(uint256 giveawayId) {
        require(
            giveaways[giveawayId].endAt >= block.timestamp,
            "Giveaway has not ended"
        );
        _;
    }

    event GiveawayCreated(uint256 indexed giveaway_id, address indexed creator);
    event GiveawayParticipantAdded(
        uint256 indexed giveaway_id,
        address indexed participant
    );
    event GiveawayWinnersSelected(
        uint256 indexed giveaway_id,
        address[] indexed winners
    );
    event GiveawayWinnerPaid(uint256 indexed giveaway_id, address winner);

    constructor(
        address[] memory _supportedERC20Tokens,
        uint256 _randomNumSeed,
        uint256 _randomNumMultiplier,
        uint256 _randomNumIncrement,
        uint256 _randomNumModulo
    ) {
        require(
            _supportedERC20Tokens.length >= 1 &&
                _supportedERC20Tokens.length <= tokensLimit,
            "Contract must be created with at least one and not more than ten supported ERC20 tokens"
        );

        owner = msg.sender;
        supportedERC20Tokens = _supportedERC20Tokens;
        giveawayIdentifierCounter = 0;

        require(_randomNumModulo > 0, "Modulo must be greater than zero");
        require(
            _randomNumSeed > 0 && _randomNumSeed < _randomNumModulo,
            "Seed number must be less than modulo"
        );
        require(
            _randomNumMultiplier > 0 && _randomNumMultiplier < _randomNumModulo,
            "Multiplier number must be less than modulo"
        );
        require(
            _randomNumIncrement > 0 && _randomNumIncrement < _randomNumModulo,
            "Increment number must be less than modulo"
        );
        randomNumSeed = _randomNumSeed;
        randomNumMultiplier = _randomNumMultiplier;
        randomNumIncrement = _randomNumIncrement;
        randomNumModulo = _randomNumModulo;
    }

    function createGiveaway(
        string calldata _name,
        uint256 _amount,
        address _tokenAddr,
        uint8 winnersCount,
        uint64 participantsCount,
        uint256 endAt
    ) external payable returns (uint256) {
        // there is a possibility that participants can be equal to winners. Ignore such case.
        require(
            participantsCount > 0 && winnersCount > 0,
            "participants and winners can never be 0"
        );
        require(
            participantsCount > winnersCount,
            "participants must always be greater than winners"
        );

        // This is to limit gas during withdrawal
        require(
            winnersCount <= 10,
            "Giveaway can only have a max of 10 winners"
        );

        require(endAt > block.timestamp, "giveaway cannot end before starting");
        require(
            endAt > block.timestamp + 15 minutes,
            "giveaway must have a duration of at least 15 minutes"
        );
        require(bytes(_name).length != 0, "giveaway name cannot be empty");

        if (_tokenAddr == zeroAddress) {
            require(
                msg.value == _amount,
                "ether sent must be equal to the amount specified"
            );
        } else if (isSupportedERC20Token(_tokenAddr)) {
            IERC20 paymentToken = IERC20(_tokenAddr);
            require(
                paymentToken.allowance(msg.sender, address(this)) >= _amount,
                "Insuficient Allowance"
            );
            require(
                paymentToken.transferFrom(msg.sender, address(this), _amount),
                "Transfer Failed"
            );
        } else {
            revert("Unsupported token provided");
        }

        giveaways[giveawayIdentifierCounter] = GiveawayDetail({
            creator: msg.sender,
            name: _name,
            amount: _amount,
            tokenAddress: _tokenAddr,
            numberOfWinners: winnersCount,
            maximumParticipants: participantsCount,
            createdAt: block.timestamp,
            endAt: endAt,
            isSuccess: true,
            hasWinners: false
        });
        giveawaysArray.push(giveawayIdentifierCounter);
        addressesToGiveaways[msg.sender].push(giveawayIdentifierCounter);

        emit GiveawayCreated(giveawayIdentifierCounter, msg.sender);
        return giveawayIdentifierCounter++;
    }

    function participateInGiveaway(
        uint256 giveawayId
    ) external giveawayExists(giveawayId) returns (bool) {
        GiveawayDetail memory giveawayInfo = giveaways[giveawayId];

        require(
            giveawayInfo.creator != msg.sender,
            "Giveaway creator cannot participate"
        );
        require(giveawayInfo.endAt < block.timestamp, "Giveaway has ended");
        // check if address is already a participants
        require(
            giveawaysParticipantsMapping[giveawayId][msg.sender] == true,
            "Already a participant for the giveaway"
        );
        require(
            giveawaysParticipantsArray[giveawayId].length <
                giveawayInfo.maximumParticipants,
            "Max participants for giveaway reached"
        );

        // add address to participants structure
        giveawaysParticipantsMapping[giveawayId][msg.sender] = true;
        giveawaysParticipantsArray[giveawayId].push(msg.sender);

        emit GiveawayParticipantAdded(giveawayId, msg.sender);
        return true;
    }

    function withdrawGiveawayPrize(
        uint256 giveawayId
    ) external giveawayExists(giveawayId) giveawayHasEnded(giveawayId) {
        GiveawayDetail memory giveawayInfo = giveaways[giveawayId];

        require(giveawayInfo.hasWinners, "Winners have not been selected");
        require(
            giveawayWinners[giveawayId][msg.sender].isValid,
            "Not a winner"
        );
        require(
            giveawayWinners[giveawayId][msg.sender].hasWithdrawnFunds,
            "A withdrawal has been issued alredy"
        );

        address[] memory _giveawayWinnersArr = giveawayWinnersArray[giveawayId];
        uint256 prizeMoney = giveawayInfo.amount / _giveawayWinnersArr.length;

        if (giveawayInfo.tokenAddress == zeroAddress) {
            (bool isSuccess, ) = payable(msg.sender).call{value: prizeMoney}(
                ""
            );
            require(isSuccess, "Failed to send prize money");
            giveawayWinners[giveawayId][msg.sender].hasWithdrawnFunds = true;
        } else {
            IERC20 paymentToken = IERC20(giveawayInfo.tokenAddress);
            require(
                paymentToken.transfer(msg.sender, prizeMoney),
                "Failed to send prize money"
            );
            giveawayWinners[giveawayId][msg.sender].hasWithdrawnFunds = true;
        }
        emit GiveawayWinnerPaid(giveawayId, msg.sender);
    }

    function pickWinners(
        uint256 giveawayId
    ) internal giveawayExists(giveawayId) giveawayHasEnded(giveawayId) {
        GiveawayDetail memory giveawayInfo = giveaways[giveawayId];
        address[] memory participants = giveawaysParticipantsArray[giveawayId];
        if (participants.length <= giveawayInfo.numberOfWinners) {
            for (uint256 i = 0; i < participants.length; i++) {
                address winner = participants[i];

                giveawayWinnersArray[giveawayId].push(winner);
                giveawayWinners[giveawayId][winner] = GiveawayWinner({
                    hasWithdrawnFunds: false,
                    isValid: true
                });
            }
        } else {
            uint256[] memory randomNumbers = chooseRandomNumbers(
                giveawayInfo.numberOfWinners,
                participants.length
            );
            for (uint256 i = 0; i < giveawayInfo.numberOfWinners; i++) {
                uint256 randomIndex = randomNumbers[i];
                address winner = participants[randomIndex];

                giveawayWinnersArray[giveawayId].push(winner);
                giveawayWinners[giveawayId][winner] = GiveawayWinner({
                    hasWithdrawnFunds: false,
                    isValid: true
                });
            }
        }
        giveawayInfo.hasWinners = true;
        emit GiveawayWinnersSelected(
            giveawayId,
            giveawayWinnersArray[giveawayId]
        );
    }

    function pickGiveawayWinners(
        uint256 giveawayId
    ) external giveawayExists(giveawayId) giveawayHasEnded(giveawayId) {
        GiveawayDetail memory giveawayInfo = giveaways[giveawayId];

        require(
            giveawayInfo.hasWinners != true,
            "Winners have selected already"
        );
        pickWinners(giveawayId);
    }

    function addERC20Token(
        address _newSupportedToken
    ) external isContractOwner(msg.sender) {
        require(_newSupportedToken != zeroAddress, "Invalid address provided");
        require(
            supportedERC20Tokens.length <= tokensLimit,
            "Only a maximum of ten ERC20 tokens are allowed"
        );

        // check that the token is not already present in the array
        for (uint256 i = 0; i < supportedERC20Tokens.length; i++) {
            if (supportedERC20Tokens[i] == _newSupportedToken) {
                revert("ERC20 token already supported");
            }
        }
        supportedERC20Tokens.push(_newSupportedToken);
    }

    function getGiveaways() external view returns (uint256[] memory) {
        return giveawaysArray;
    }

    function getGiveaway(
        uint256 giveawayId
    ) external view giveawayExists(giveawayId) returns (GiveawayDetail memory) {
        return giveaways[giveawayId];
    }

    function getMyGiveaways(
        address _address
    ) external view returns (uint256[] memory) {
        return addressesToGiveaways[_address];
    }

    function isSupportedERC20Token(address addr) internal view returns (bool) {
        for (uint256 i = 0; i < supportedERC20Tokens.length; i++) {
            if (supportedERC20Tokens[i] == addr) {
                return true;
            }
        }
        return false;
    }

    function getSupportedERC20Tokens()
        external
        view
        returns (address[] memory)
    {
        return supportedERC20Tokens;
    }

    function chooseRandomNumbers(
        uint256 numsToGenerate,
        uint256 maxNumToChoose
    ) internal returns (uint256[] memory) {
        uint256[] memory randNums = new uint256[](numsToGenerate);
        for (uint256 i = 0; i < numsToGenerate; i++) {
            uint256 randNum = (randomNumMultiplier *
                randomNumSeed +
                randomNumIncrement) % randomNumModulo;
            randNums[i] = randNum % maxNumToChoose;
            randomNumSeed = randNum;
        }
        return randNums;
    }

    fallback() external payable {}

    receive() external payable {}
}