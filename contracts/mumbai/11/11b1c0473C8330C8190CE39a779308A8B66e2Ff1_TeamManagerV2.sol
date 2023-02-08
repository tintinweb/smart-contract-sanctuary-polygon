// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./interfaces/IGen2PlayerToken.sol";
import "./abstracts/team-manager-parts/StakeValidator.sol";
import "./abstracts/team-manager-parts/Staker.sol";

import "./abstracts/team-manager-parts/TeamPointsCalculator.sol";

/**
 * @title TeamManager -- .
 */
contract TeamManagerV2 is TeamPointsCalculator {
    // _______________ Initializer _______________

    /**
     * @dev Initializes this contract by setting the deployer as the initial administrator that has the
     * `DEFAULT_ADMIN_ROLE` role and the following parameters:
     * @param _gen2PlayerToken   An address of the second generation player NFT contract that mints duplicates of the
     * first generation player NF tokens.
     * @param _calculator   The contract that calculates scores of the specific first generation player NF tokens.
     *
     * @notice It is used as the constructor for upgradeable contracts.
     */
    function initialize(
        address _gen2PlayerToken,
        address _teamsStakingDeadlinesContract,
        address _calculator
    ) external initializer {
        init_SeasonSync_unchained(_msgSender());
        init_StakeValidator_unchained(_gen2PlayerToken, _teamsStakingDeadlinesContract);
        init_Staker_unchained();
        init_TeamPointsCalculator_unchained(_calculator);
    }

    // _______________ Gap reserved space _______________

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IGen2PlayerToken is IERC721Upgradeable {
    function nftIdToDivisionId(uint256) external view returns (uint256);

    function nftIdToImageId(uint256) external view returns (uint256);

    function nftIdToSeasonId(uint256) external view returns (uint256);

    function getTokenPosition(uint256 _tokenId) external view returns (uint256 position);

    function updateSeasonId() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "../common-parts/SeasonSync.sol";
import "../../interfaces/IGen2PlayerToken.sol";
import "../../interfaces/ITeamsStakingDeadlines.sol";

/**
 * @dev
 */
abstract contract StakeValidator is SeasonSync {
    // _______________ Storage _______________

    // ____ External Gen2 NF Player Token interface ____

    /// @notice External Genesis Gen2 NF Player Token contract interface. This tokens is staked by users
    IGen2PlayerToken public gen2PlayerToken;

    // ____ External Teams Staking Deadlines interface ____

    /// @notice External Teams Staking Deadlines contract interface. This contract is used to store staking deadlines for teams
    ITeamsStakingDeadlines public teamsStakingDeadlinesContract;

    // ____  To check the filling of competing team positions (roles) during staking ____

    /// @notice Staking limitations setting, e.g. user can stake 1 QB, 2 RB, 2 WR, 1 TE, 3 DEF Line, 1 LB, 1 DEF Back + flex staking (see above)
    // Season ID => position code => staking amount
    mapping(uint256 => mapping(uint256 => uint256)) public positionNumber;

    /**
     * @notice Flex position code (see flex position staking limitation description below)
     * @dev Other position codes will be taken from admin and compared to position codes specified in the Genesis NomoNFT (see NomoNFT contract to find position codes and CardImages functionality)
     */
    uint256 public constant FLEX_POSITION = uint256(keccak256(abi.encode("FLEX_POSITION")));

    /// @notice Custom positions flex limitation, that's a places for staking where several positions code can stand/be, e.g. 3 staking places for QB, RB, WR or TE, so, for example, user can use them as 2 QB + 1 TE or 1 WR + 1 RB + 1 TE or in other way when in total there will 3 NFTs (additionally to usual limitations) with specified positions
    // Season ID => position code => is included in flex limitation
    mapping(uint256 => mapping(uint256 => bool)) public isFlexPosition;

    /// @notice  amount of staking places for flex limitation
    // Season ID => flex position number
    mapping(uint256 => uint256) public flexPositionNumber;

    // Season ID => token id => is token staked in the flex position
    mapping(uint256 => mapping(uint256 => bool)) public isPlayerInFlexPosition;

    /// @notice Staked tokens by position to control staking limitations
    // Season ID => user => position code => amount
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) public userPositionNumber;

    // _______________ Events _______________

    /// @notice When staked NFT contract changed
    event Gen2PlayerTokenSet(address _gen2PlayerToken);

    /// @notice When staking deadlines contract changed
    event TeamsStakingDeadlinesContractSet(address _teamsStakingDeadlinesContract);

    /// @notice When staking limitation updated
    event PositionNumberSet(uint256 _season, uint256 indexed _position, uint256 _newStakingLimit);

    /// @notice When positions are added or deleted from flex limitation
    event FlexPositionSet(uint256 _season, uint256 indexed _position, bool _isFlexPosition);

    /// @notice When flex limit amount is changed
    event FlexPositionNumberSet(uint256 _season, uint256 indexed _newNumber);

    // _______________ Modifiers _______________

    // Check that the `_address` is not zero
    modifier nonzeroAddress(address _address) {
        require(_address != address(0), "Zero address");
        _;
    }

    /*
     * Safety check that player token owner did not forget to pass a valid position code.
     *
     * `_position`   Integer number code that represents specific position of a player. This value should exist in the
     * Genesis NomoNFT contract (see NomoNFT contract to find position codes and CardImages functionality).
     *
     * NOTE Position code with zero value is potentially unsafe, so it is better not to use it at all.
     */
    modifier nonzeroPosition(uint256 _position) {
        require(_position != 0, "position code is 0, check position code");
        _;
    }

    // _______________ Initializer _______________

    function init_StakeValidator_unchained(address _gen2PlayerToken, address _teamsStakingDeadlinesContract)
        internal
        onlyInitializing
    {
        gen2PlayerToken = IGen2PlayerToken(_gen2PlayerToken);
        emit Gen2PlayerTokenSet(_gen2PlayerToken);

        setTeamsStakingDeadlinesContract(_teamsStakingDeadlinesContract);
    }

    // _______________ External functions _______________

    /**
     * @notice Change NFT address
     *
     * @param _gen2PlayerToken New NFT address
     */
    function setGen2PlayerToken(address _gen2PlayerToken)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonzeroAddress(_gen2PlayerToken)
    {
        gen2PlayerToken = IGen2PlayerToken(_gen2PlayerToken);
        emit Gen2PlayerTokenSet(_gen2PlayerToken);
    }

    /**
     * @notice Change staking deadlines contract address
     *
     * @param _teamsStakingDeadlinesContract New staking deadlines contract address
     */
    function setTeamsStakingDeadlinesContract(address _teamsStakingDeadlinesContract)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonzeroAddress(_teamsStakingDeadlinesContract)
    {
        teamsStakingDeadlinesContract = ITeamsStakingDeadlines(_teamsStakingDeadlinesContract);
        emit TeamsStakingDeadlinesContractSet(_teamsStakingDeadlinesContract);
    }

    /**
     * @notice Allows contract owner to set limitations for staking ( see flex limitations setter below)
     * @dev This is only usual limitation, in addition there are positions flex limitation
     * @param _position integer number code that represents specific position; ths value must exist in the Genesis NomoNFT (see NomoNFT contract to find position codes and CardImages functionality). Notice - this function reverts if _position is 0
     * @param _howMany amount of players with specified position that user can stake. Notice - user can stake some positions over this limit if these positions are included in the flex limitation
     */
    function setPositionNumber(uint256 _position, uint256 _howMany)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonzeroPosition(_position)
    {
        uint256 season = seasonId;
        positionNumber[season][_position] = _howMany;
        emit PositionNumberSet(season, _position, _howMany);
    }

    /**
     * @notice Allows contract owner to change positions in flex limitation
     * @dev This is addition to usual limitation
     * @param _position integer number code that represents specific position; ths value must exist in the Genesis NomoNFT (see NomoNFT contract to find position codes and CardImages functionality). Notice - this function reverts if _position is 0
     * @param _isFlexPosition if true, then position is in the flex, if false, then tokens with this positions can't be staked in flex limitation places
     */
    function setFlexPosition(uint256 _position, bool _isFlexPosition)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonzeroPosition(_position)
    {
        uint256 season = seasonId;
        require(
            isFlexPosition[season][_position] != _isFlexPosition,
            "passed _position is already with passed bool value"
        );
        isFlexPosition[season][_position] = _isFlexPosition;
        emit FlexPositionSet(season, _position, _isFlexPosition);
    }

    /**
     * @notice Allows contract owner to set number of tokens which can be staked as a part of the flex limitation
     * @dev If new limit is 0, then it means that flex limitation disabled. Note: you can calculate total number of tokens that can be staked by user if you will sum flex limitation amount and all limits for all positions.
     * @param _newFlexPositionNumber number of tokens that can be staked as a part of the positions flex limit
     */
    function setFlexPositionNumber(uint256 _newFlexPositionNumber) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 season = seasonId;
        flexPositionNumber[season] = _newFlexPositionNumber;
        emit FlexPositionNumberSet(season, _newFlexPositionNumber);
    }

    // _______________ Internal functions _______________

    /**
     * @notice Check limitations and fill the position limit with token if there is a free place.
     * @dev Reverts if user reached all limits for token's position
     * @param _tokenId Gen2PlayerToken id user wants to stake
     * @param _user User's address
     */
    function validatePosition(uint256 _tokenId, address _user) internal {
        // get token's position
        uint256 position = gen2PlayerToken.getTokenPosition(_tokenId);
        require(position != 0, "Position code can't be zero");
        // check limits
        // 1. check simple limitations
        uint256 season = seasonId;
        mapping(uint256 => uint256) storage userPositionNum = userPositionNumber[season][_user];
        if (userPositionNum[position] < positionNumber[season][position]) {
            // stake using simple limit
            userPositionNum[position] += 1;
        } else {
            // check if this position can be staked in flex limit
            require(isFlexPosition[season][position], "Simple limit is reached and can't stake in flex");
            // check that flex limit isn't reached
            uint256 userFlexPosNumber = userPositionNum[FLEX_POSITION];
            require(userFlexPosNumber < flexPositionNumber[season], "Simple and flex limits reached");
            // if requirements passed, then we can stake this token in flex limit
            userPositionNum[FLEX_POSITION] += 1;
            isPlayerInFlexPosition[season][_tokenId] = true;
        }
    }

    function unstakePosition(uint256 _tokenId, address _user) internal {
        // Getting of token's position.
        uint256 position = gen2PlayerToken.getTokenPosition(_tokenId);
        require(position != 0, "Position code can't be zero");

        uint256 season = seasonId;
        if (isPlayerInFlexPosition[season][_tokenId]) {
            userPositionNumber[season][_user][FLEX_POSITION] -= 1;
            isPlayerInFlexPosition[season][_tokenId] = false;
        } else {
            userPositionNumber[season][_user][position] -= 1;
        }
    }

    // _______________ Deadline validation internal functions _______________

    /**
     * @notice Check if token's staking deadline is greater than block.timestamp
     * @dev Reverts if token's staking deadline is less than block.timestamp
     * @param _tokenId Gen2PlayerToken id user wants to stake
     */
    function validateDeadline(uint256 _tokenId) internal view {
        uint256 tokenCardImageId = gen2PlayerToken.nftIdToImageId(_tokenId);
        uint256 stakingDeadline = teamsStakingDeadlinesContract.getCardImageTeamDeadline(tokenCardImageId);
        require(stakingDeadline > block.timestamp, "Token's staking deadline is less than current timestamp");
    }

    // _______________ Gap reserved space _______________

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[43] private gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./StakeValidator.sol";

/**
 * @dev
 */
abstract contract Staker is StakeValidator {
    // _______________ Storage _______________

    /*
     * Stores a division ID of a user (after the shuffle process on FantasyLeague contract).
     * Season ID => (user => [division ID + 1]).
     * NOTE Plus 1, because the zero value is used to check that the user has been added.
     */
    mapping(uint256 => mapping(address => uint256)) private userDivisionIncreasedId;

    // ____ For competing team squad ____

    /// @notice Players staked by the user. Staked players are active team of the user
    // Season ID => (user => staked players)
    mapping(uint256 => mapping(address => uint256[])) public stakedPlayers;

    /*
     * Stores a player token index in the array of staked players.
     * Season ID => (user => (token ID => [1 + token index in the stakedPlayers[user] array])).
     * NOTE Plus 1, because the zero value is used to check that the player token ID has been added.
     */
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) private stakedPlayerIncreasedIndex;

    // _______________ Roles _______________

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    // _______________ Events _______________

    event UserDivisionIdSet(uint256 _season, address _user, uint256 _divisionId);

    /// @notice When user stakes new token to the team
    event PlayerStaked(uint256 _season, address _user, uint256 _tokenId);

    /// @notice When user unstakes token from the team
    event PlayerUnstaked(uint256 _season, address _user, uint256 _tokenId);

    /**
     * @dev Emitted when the player with `_tokenId` is removed from the team of `_user`.
     *
     * @param _season A season in which the player was removed from user's team.
     * @param _user A user from whose team the player was removed.
     * @param _tokenId A token ID of the player to be removed from user's team.
     */
    event PlayerForciblyUnstaked(uint256 _season, address _user, uint256 _tokenId);

    // _______________ Modifiers _______________

    // Check that a `_user` is added
    modifier addedUser(uint256 _season, address _user) {
        require(isUserAdded(_season, _user), "Unknown user");
        _;
    }

    // _______________ Initializer _______________

    function init_Staker_unchained() internal onlyInitializing {}

    // _______________ External functions _______________

    /**
     * @dev Sets a division ID of a user.
     *
     * @param _user   A user address.
     * @param _divisionId   A user division ID.
     */
    function setUserDivisionId(address _user, uint256 _divisionId) external onlyFantasyLeague nonzeroAddress(_user) {
        // Check if user is already added
        uint256 season = seasonId;
        require(!isUserAdded(season, _user), "The user has already been added");

        // Plus 1, because the zero value is used to check that the user has been added
        userDivisionIncreasedId[season][_user] = _divisionId + 1;
        emit UserDivisionIdSet(season, _user, _divisionId);
    }

    /**
     * @notice Adds players to caller's team
     * @dev Uses stakePlayer() function for each tokenId in the passed array. 
     * @dev Caller must be registered user and there must be free places to stake (unused limits).
     * @param _tokenIds An array of token IDs.
     */
    // prettier-ignore
    function stakePlayers(uint256[] calldata _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; ++i)
            _stakePlayer(_tokenIds[i], _msgSender());
    }

    /**
     * @notice Adds player to caller's team
     * @dev internal function 
     * @param _tokenId Player NFT tokenId
     * @param _user Address of current user 
     */
    function _stakePlayer(uint256 _tokenId, address _user) internal addedUser(seasonId, _user) {
        // Check that `_tokenId` is in a right division
        require(
            getCorrectedId(userDivisionIncreasedId[seasonId][_user]) == 
                gen2PlayerToken.nftIdToDivisionId(_tokenId),
            "Token from another division"
        );
        // Check that `_tokenId` belongs to the current season
        require(gen2PlayerToken.nftIdToSeasonId(_tokenId) == seasonId, "Token from another season");

        // Adding of a player to caller's team
        addToTeam(_tokenId, _user);
        // Taking of a player token
        gen2PlayerToken.transferFrom(_user, address(this), _tokenId);
        
        emit PlayerStaked(seasonId, _user, _tokenId);
    }

    /**
     * @notice Adds player to caller's team
     * @param _tokenId Player NFT tokenId
     */
    function stakePlayer(uint256 _tokenId) external {
        _stakePlayer(_tokenId, _msgSender());
    }

    /**
     * @notice Adds player to user's team
     * @dev Caller must be registered Relayer and there must be free places to stake (unused limits).
     * @param _tokenId Player NFT tokenId
     * @param _user Address on whose behalf acting relayer
     */
    function stakePlayerForUser(uint256 _tokenId, address _user) external onlyRole(RELAYER_ROLE) {
        _stakePlayer(_tokenId, _user);
    }

    /**
     * @notice Adds players to user's team
     * @dev Uses _stakePlayer() function for each tokenId in the passed array. 
     * @dev Caller must be relayer and there must be free places to stake (unused limits).
     * @param _tokenIds An array of token IDs.
     * @param _user Address of user on whose behalf acting relayer
     */
    // prettier-ignore
    function stakePlayersForUser(uint256[] calldata _tokenIds, address _user) external onlyRole(RELAYER_ROLE) {
        for (uint256 i = 0; i < _tokenIds.length; ++i)
            _stakePlayer(_tokenIds[i], _user);
    }
    
    /**
     * @notice Removes player from caller's team
     * @dev Uses unstakePlayer() function for each tokenId in the passed array. 
     * @dev Caller must be registered user and there must be staked players in the team.
     * @param _tokenId   A token ID of the player.
     */
    function unstakePlayer(uint256 _tokenId) public {
        _unstakePlayer(_tokenId, _msgSender());
    }

    /**
     * @notice Removes player from user's team.
     * @dev Uses unstakePlayer() function for tokenId. 
     * @dev Caller must be relayer and there must be staked players in the team.
     * @param _tokenId   A token ID of the player.
     * @param _user Address on whose behalf acting relayer.
     */
    function unstakePlayerForUser(uint256 _tokenId, address _user) external onlyRole(RELAYER_ROLE) {
        _unstakePlayer(_tokenId, _user);
    }

    /**
     * @notice Removes players from caller's team
     * @dev Uses unstakePlayer() function for each tokenId in the passed array. Caller must be registered user and there must be staked players in the team.
     * @param _tokenIds   An array of token IDs.
     */
    // prettier-ignore
    function unstakePlayers(uint256[] calldata _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; ++i)
            unstakePlayer(_tokenIds[i]);
    }

    /**
     * @notice Removes players from user's team.
     * @dev Caller must be relayer contract and there must be free places to stake (unused limits).
     * @param _tokenIds An array of token IDs.
     * @param _user Address of user on whose behalf acting relayer.
     */
     // prettier-ignore
     function unstakePlayersForUser(uint256[] calldata _tokenIds, address _user) external onlyRole(RELAYER_ROLE) {
        for (uint256 i = 0; i < _tokenIds.length; ++i) 
        _unstakePlayer(_tokenIds[i], _user);
    }
    
    /**
     * @notice Removes player from caller's team
     * @dev Internal function.
     * @param _tokenId Player NFT tokenId
     * @param _user Address of current user 
     */
    function _unstakePlayer(uint256 _tokenId, address _user) internal addedUser(seasonId, _user) {
        deleteFromTeam(_user, _tokenId, false);
        gen2PlayerToken.transferFrom(address(this), _user, _tokenId);
        emit PlayerUnstaked(seasonId, _user, _tokenId);
    }

    /**
     * @dev Forcibly removes players with `_tokenIds` from the team of `_user` by the administrator.
     *
     * Requirements:
     *  - The caller should have the default admin role (`DEFAULT_ADMIN_ROLE`).
     *  - The account, that owns the players, should be a user.
     *  - The players should be staked by a user.
     *  - The position codes of the players should not be equal to zero.
     *
     * @param _user   The owner of the player.
     * @param _tokenIds   An array of token IDs of the players to be removed from the team of their owner.
     */
    // prettier-ignore
    function forciblyUnstakePlayers(address _user, uint256[] calldata _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; ++i)
            forciblyUnstakePlayer(_user, _tokenIds[i]);
    }

    /**
     * @dev Forcibly removes the player with `_tokenId` from the team of `_user` by the administrator..
     *
     * Requirements:
     *  - The caller should have the default admin role (`DEFAULT_ADMIN_ROLE`).
     *  - The account, that owns the players, should be a user.
     *  - The player should be staked by a user.
     *  - The position code of the player should not be equal to zero.
     *
     * @param _user   The owner of the player.
     * @param _tokenId   A token ID of the player to be removed from the team of its owner.
     */
    function forciblyUnstakePlayer(address _user, uint256 _tokenId)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        addedUser(seasonId, _user)
    {
        deleteFromTeam(_user, _tokenId, true);
        gen2PlayerToken.transferFrom(address(this), _user, _tokenId);
        uint256 season = seasonId;
        emit PlayerForciblyUnstaked(season, _user, _tokenId);
        emit PlayerUnstaked(season, _user, _tokenId);
    }

    // ____ Extra view functionality for back end ____

    function getUserDivisionId(uint256 _season, address _user)
        external
        view
        addedUser(_season, _user)
        returns (uint256)
    {
        return getCorrectedId(userDivisionIncreasedId[_season][_user]);
    }

    function getStakedPlayerIndex(
        uint256 _season,
        address _user,
        uint256 _tokenId
    ) external view returns (uint256) {
        require(isPlayerStaked(_season, _user, _tokenId), "Such a player is not staked");
        return getCorrectedIndex(stakedPlayerIncreasedIndex[_season][_user][_tokenId]);
    }

    /**
     * @notice Returns an array of token ids staked by the specified user
     * @return Array of Gen2Player NFTs ids
     */
    function getStakedPlayersOfUser(uint256 _season, address _user)
        external
        view
        addedUser(_season, _user)
        returns (uint256[] memory)
    {
        return stakedPlayers[_season][_user];
    }

    // _______________ Public functions _______________

    function isUserAdded(uint256 _season, address _user) public view returns (bool) {
        return userDivisionIncreasedId[_season][_user] != 0;
    }

    function isPlayerStaked(
        uint256 _season,
        address _user,
        uint256 _tokenId
    ) public view returns (bool) {
        return stakedPlayerIncreasedIndex[_season][_user][_tokenId] != 0;
    }

    // _______________ Private functions _______________

    function getCorrectedId(uint256 _increasedId) private pure returns (uint256) {
        return _increasedId - 1;
    }

    function getCorrectedIndex(uint256 _increasedIndex) private pure returns (uint256) {
        return _increasedIndex - 1;
    }

    function addToTeam(uint256 _tokenId, address _user) private {
        uint256 season = seasonId;
        require(!isPlayerStaked(season, _user, _tokenId), "This player has already been staked");
        // Reverts if there is no free space left for a token with such a position
        validatePosition(_tokenId, _user);
        // Reverts if staking after deadline
        validateDeadline(_tokenId);

        uint256[] storage players = stakedPlayers[season][_user];
        players.push(_tokenId);
        stakedPlayerIncreasedIndex[season][_user][_tokenId] = players.length;
    }

    /*
     * `_force == true` means that the player with `_tokenId` is forcibly removed by the administrator. It is used for
     * ignore of a stake deadline.
     */
    // prettier-ignore
    function deleteFromTeam(address _user, uint256 _tokenId, bool _force) private {
        uint256 season = seasonId;
        require(isPlayerStaked(season, _user, _tokenId), "This player is not staked");

        // Reverse if unstaking after a deadline, when removal by a non-administrator.
        if (!_force)
            validateDeadline(_tokenId);

        unstakePosition(_tokenId, _user);

        uint256[] storage players = stakedPlayers[season][_user];
        mapping(uint256 => uint256) storage increasedIndex = stakedPlayerIncreasedIndex[season][_user];

        // Deletion of the player from the array of staked players and writing down of its index in the mapping.
        // Index of the player in the array of staked players.
        uint256 playerIndex = getCorrectedIndex(increasedIndex[_tokenId]);
        uint256 lastPlayerTokenId = players[players.length - 1];
        // Replacing of the deleted player with the last one in the array.
        players[playerIndex] = lastPlayerTokenId;
        // Cutting off the last player.
        players.pop();

        // Replacing of an index of the last player with the deleted one.
        increasedIndex[lastPlayerTokenId] = playerIndex + 1;
        // Reset of the deleted player index.
        delete increasedIndex[_tokenId];
    }

    // _______________ Gap reserved space _______________

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./Staker.sol";
import "../../../gen1/interfaces/INomoCalculator.sol";

/**
 * @title
 */
abstract contract TeamPointsCalculator is Staker {
    // _______________ Storage _______________

    // The calculator of a player points
    INomoCalculator public calculator;

    // Timestamp when the current week (of the competitions on the Fantasy League contract) has started
    uint256 public currentGameStartTime;

    // _______________ Events _______________

    event CalculatorSet(address _calculator);

    event CurrentGameStartTimeSet(uint256 _timestamp);

    // _______________ Initializer _______________

    function init_TeamPointsCalculator_unchained(address _calculator) internal onlyInitializing {
        calculator = INomoCalculator(_calculator);
        emit CalculatorSet(_calculator);
    }

    // _______________ External functions _______________

    /**
     * @dev Sets the calculator of a player points.
     *
     * @param _calculator   A new calculator address.
     */
    function setCalculator(address _calculator) external onlyRole(DEFAULT_ADMIN_ROLE) nonzeroAddress(_calculator) {
        calculator = INomoCalculator(_calculator);
        emit CalculatorSet(_calculator);
    }

    /**
     * @dev Sets the timestamp when the current week (of the competitions on the Fantasy League contract) has started.
     *
     * @param _timestamp   A new timestamp.
     */
    function setCurrentGameStartTime(uint256 _timestamp) external onlyFantasyLeague {
        currentGameStartTime = _timestamp;
        emit CurrentGameStartTimeSet(_timestamp);
    }

    /**
     * @dev Calculates current scores of `_firstUser`'s team and `_secondUser`'s team.
     *
     * @param _firstUser   A first user address.
     * @param _secondUser   A second user address.
     * @return   Two numbers that represent the current scores of the first and second user teams.
     */
    function calcTeamScoreForTwoUsers(address _firstUser, address _secondUser)
        external
        view
        returns (uint256, uint256)
    {
        return (calculateUserTeamScore(_firstUser), calculateUserTeamScore(_secondUser));
    }

    // _______________ Public functions _______________

    /**
     * @dev Calculates a current score of the `_user`'s team.
     *
     * @param _user   A user address.
     * @return teamScore   Current score of the `_user`'s team.
     */
    function calculateUserTeamScore(address _user) public view returns (uint256 teamScore) {
        uint256[] storage team = stakedPlayers[seasonId][_user];

        // Calculation of total user's score taking into account the points of each player in a team
        teamScore = 0;
        for (uint256 i = 0; i < team.length; ++i) {
            teamScore += calculator.calculatePoints(team[i], currentGameStartTime);
        }
    }

    // _______________ Gap reserved space _______________

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../../interfaces/IFantasyLeague.sol";

/**
 * @title
 */
abstract contract SeasonSync is AccessControlUpgradeable {
    // _______________ Storage _______________

    IFantasyLeague public fantasyLeague;

    uint256 public seasonId;

    // _______________ Events _______________

    event FantasyLeagueSet(address _fantasyLeague);

    event SeasonIdUpdated(uint256 indexed _seasonId);

    // _______________ Modifiers _______________

    modifier onlyFantasyLeague() {
        require(_msgSender() == address(fantasyLeague), "Function should only be called by the FantasyLeague contract");
        _;
    }

    // _______________ Initializer _______________

    function init_SeasonSync_unchained(address _admin) internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    // _______________ External functions _______________

    function setFantasyLeague(address _fantasyLeague) external onlyRole(DEFAULT_ADMIN_ROLE) {
        fantasyLeague = IFantasyLeague(_fantasyLeague);
        emit FantasyLeagueSet(_fantasyLeague);
    }

    function updateSeasonId() external {
        require(
            _msgSender() == address(fantasyLeague) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Should be called by the FantasyLeague contract or administrator"
        );

        uint256 season = fantasyLeague.getSeasonId();
        seasonId = season;
        emit SeasonIdUpdated(season);
    }

    // _______________ Gap reserved space _______________

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

/// @title Contract which stores staking deadlines for teams and binds CardImages to teams.
interface ITeamsStakingDeadlines {
    /**
     * @notice Get team id for a card image.
     * @param _cardImageId card image id.
     * @return _teamId team id
     */
    function cardImageToTeam(uint256 _cardImageId) external view returns (uint256 _teamId);

    /**
     * @notice Get staking deadline for a team.
     * @param _teamId team id.
     * @return _deadline staking deadline
     */
    function teamDeadline(uint256 _teamId) external view returns (uint256 _deadline);

    /**
     * @notice Get team name for a team.
     * @param _teamId team id.
     * @return _name team name
     */
    function teamName(uint256 _teamId) external view returns (string memory _name);

    /**
     * @notice Get CardImage's team deadline.
     * @param _cardImageId Card image id.
     * @return Team deadline.
     */
    function getCardImageTeamDeadline(uint256 _cardImageId) external view returns (uint256);

    /**
     * @notice Get CardImage's team name.
     * @param _cardImageId Card image id.
     * @return Team name.
     */
    function getCardImageTeamName(uint256 _cardImageId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "../abstracts/mega-league-parts/DivisionWinnerStatsStruct.sol";

interface IFantasyLeague {
    function getSeasonId() external view returns (uint256);

    function addUser(address _user) external;

    function getNumberOfDivisions() external view returns (uint256);

    function getCurrentWeek() external view returns (uint256);

    /**
     * @notice How many users in the game registered
     *
     * @return Amount of the users
     */
    function getNumberOfUsers() external view returns (uint256);

    /**
     * @dev How many users in one division.
     * @return   Number.
     */
    function DIVISION_SIZE() external view returns (uint256);

    function getSomeDivisionWinners(
        uint256 _season,
        uint256 _from,
        uint256 _to
    ) external view returns (address[] memory divisionWinners);

    function getSomeDivisionWinnersStats(
        uint256 _season,
        uint256 _from,
        uint256 _to
    ) external view returns (DivisionWinnerStats[] memory divisionWinnersStats);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

struct DivisionWinnerStats {
    uint256 totalPoints;
    uint32 wins;
    uint32 ties;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface INomoCalculator {
    function calculatePoints(uint256 _tokenId, uint256 _gameStartTime) external view returns (uint256 points);
}