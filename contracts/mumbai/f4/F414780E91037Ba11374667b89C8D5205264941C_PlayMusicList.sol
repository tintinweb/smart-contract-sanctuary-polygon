/**
 *Submitted for verification at polygonscan.com on 2022-06-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IGOMTOKEN {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IGSOUND {
    function existed(uint256 tokenId) external returns (bool);
}

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract PlayMusicList is Ownable {
    using SafeMath for uint256;

    IGOMTOKEN public gomToken;
    IGSOUND public godSound;

    struct MusicInfo {
        uint256 likeBallot;
        uint256 dislikeBallot;
        uint256 validBallot;
        bool onMusicList;
    }
    // Info of each music.
    mapping (uint256 => MusicInfo) public musicInfo;
    uint256[] public musicList;  //length limit: 200
    uint256 public lengthLimit = 200;
    uint256 public upBase = 100;

    struct UserInfo {
        uint256 likeVoteNumber;
        uint256 dislikeVoteNumber;
        uint256 stakeRank;
        uint256 stakeTime;
    }
    // Info of each user that stakes LP tokens for one music.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    uint256 public startTime;

    uint256 public clacBaseTime;

    address public teamPool;
    address public addedPool;

    event Vote(address indexed user, uint256 musicID, uint256 voteNumber);
    event Blackball(address indexed user, uint256 musicID, uint256 voteNumber);
    event BackVote(address indexed user, uint256 musicID, uint256 backNumber);
    event BackBlackball(address indexed user, uint256 musicID, uint256 backNumber);

    event VoteReward(address indexed user, uint256 rewardAmount, uint256 teamReward, uint256 addedReward);
    event BlackballReward(address indexed user, uint256 rewardAmount, uint256 teamReward, uint256 addedReward);


    constructor(IGOMTOKEN _gomToken, IGSOUND _godSound) {
        gomToken = _gomToken;
        godSound = _godSound;
        teamPool = msg.sender;
        addedPool = msg.sender;
    }

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'BuySharesNFT: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function vote(uint256 musicID, uint256 voteNumber) lock public {
        ///First judge if the music exists from music NFT's contract.
        require(godSound.existed(musicID), "This music NFT is not existed.");

        gomToken.transferFrom(msg.sender, address(this), voteNumber);

        MusicInfo storage music = musicInfo[musicID];
        UserInfo storage user = userInfo[musicID][msg.sender];

        if (user.likeVoteNumber > 0 || user.dislikeVoteNumber > 0) _claimReward(musicID, msg.sender);

        music.likeBallot = music.likeBallot.add(voteNumber);
        uint256[] memory _musicList = musicList;

        uint256 rank;

        if (music.onMusicList) {
            music.validBallot = music.validBallot.add(voteNumber);
            //sort music
            for (uint256 i = 0; i < _musicList.length; i++) {
                //Get the rank of music before ranking.
                if (_musicList[i] == musicID) {
                    rank = i + 1;
                    break;
                }
            }
            while (rank > 1) {
                if (music.validBallot > musicInfo[_musicList[rank - 2]].validBallot) {
                    (_musicList[rank - 1], _musicList[rank - 2]) = (_musicList[rank - 2], _musicList[rank - 1]);
                    rank--;
                } else {
                    break;
                }
            }
        } else {
            if (music.likeBallot > music.dislikeBallot) {
                music.validBallot = music.likeBallot.sub(music.dislikeBallot);
            }
            if (music.validBallot > 0 && _musicList.length < lengthLimit) {
                //add one music to the music list
                musicList.push(musicID);
                _musicList = musicList;
                music.onMusicList = true;
                rank = _musicList.length;

                while (rank > 1) {
                    if (music.validBallot > musicInfo[_musicList[rank - 2]].validBallot) {
                        (_musicList[rank - 1], _musicList[rank - 2]) = (_musicList[rank - 2], _musicList[rank - 1]);
                        rank--;
                    } else {
                        break;
                    }
                }
            } else if (music.validBallot > musicInfo[_musicList[_musicList.length - 1]].validBallot) {
                //replace the music of the last bank
                musicInfo[_musicList[_musicList.length - 1]].onMusicList = false;
                music.onMusicList = true;
                _musicList[_musicList.length - 1] = musicID;
                rank = _musicList.length;

                while (rank > 1) {
                    if (music.validBallot > musicInfo[_musicList[rank - 2]].validBallot) {
                        (_musicList[rank - 1], _musicList[rank - 2]) = (_musicList[rank - 2], _musicList[rank - 1]);
                        rank--;
                    } else {
                        break;
                    }
                }
            }
        }

        musicList = _musicList;
        user.likeVoteNumber = user.likeVoteNumber.add(voteNumber);
        user.stakeRank = rank;
        user.stakeTime = block.timestamp;

        emit Vote(msg.sender, musicID, voteNumber);
    }

    function blackball(uint256 musicID, uint256 voteNumber) lock public {
        ///First judge if the music exists from music NFT's contract.
        require(godSound.existed(musicID), "This music NFT is not existed.");

        gomToken.transferFrom(msg.sender, address(this), voteNumber);

        MusicInfo storage music = musicInfo[musicID];
        UserInfo storage user = userInfo[musicID][msg.sender];

        music.dislikeBallot = music.dislikeBallot.add(voteNumber);
        uint256[] memory _musicList = musicList;

        user.dislikeVoteNumber = user.dislikeVoteNumber.add(voteNumber);
        user.stakeTime = block.timestamp;

        if (!music.onMusicList) return;

        uint256 rank;

        for (uint256 i = 0; i < _musicList.length; i++) {
            //Get the rank of music before ranking.
            if (_musicList[i] == musicID) {
                rank = i + 1;
                break;
            }
        }

        if (music.likeBallot > music.dislikeBallot) {
            music.validBallot = music.likeBallot.sub(music.dislikeBallot);

            while (rank < _musicList.length) {
                if (music.validBallot < musicInfo[_musicList[rank]].validBallot) {
                    (_musicList[rank - 1], _musicList[rank]) = (_musicList[rank], _musicList[rank - 1]);
                    rank++;
                } else {
                    break;
                }
            }
        } else {
            music.validBallot = 0;
            music.onMusicList = false;

            while (rank < _musicList.length) {
                (_musicList[rank - 1], _musicList[rank]) = (_musicList[rank], _musicList[rank - 1]);
                rank++;
            }
            rank = 0;
        }

        musicList = _musicList;
        if (music.validBallot == 0) musicList.pop();
        user.stakeRank = rank;

        emit Blackball(msg.sender, musicID, voteNumber);
    }

    function backVote(uint256 musicID, uint256 backNumber) lock public {
        MusicInfo storage music = musicInfo[musicID];
        UserInfo storage user = userInfo[musicID][msg.sender];

        require(user.likeVoteNumber >= backNumber, "Voted number is not enough.");

        music.likeBallot = music.likeBallot.sub(backNumber);

        user.likeVoteNumber = user.likeVoteNumber.sub(backNumber);
        user.stakeTime = block.timestamp;

        if (!music.onMusicList) {
            user.stakeRank = 0;
            if (music.likeBallot > music.dislikeBallot) {
                music.validBallot = music.likeBallot.sub(music.dislikeBallot);
            }
            return;
        }

        uint256[] memory _musicList = musicList;

        uint256 rank;
        for (uint256 i = 0; i < _musicList.length; i++) {
            //Get the rank of music before ranking.
            if (_musicList[i] == musicID) {
                rank = i + 1;
                break;
            }
        }

        if (music.likeBallot > music.dislikeBallot) {
            music.validBallot = music.likeBallot.sub(music.dislikeBallot);

            while (rank < _musicList.length) {
                if (music.validBallot < musicInfo[_musicList[rank]].validBallot) {
                    (_musicList[rank - 1], _musicList[rank]) = (_musicList[rank], _musicList[rank - 1]);
                    rank++;
                } else {
                    break;
                }
            }
        } else {
            music.validBallot = 0;
            music.onMusicList = false;

            while (rank < _musicList.length) {
                (_musicList[rank - 1], _musicList[rank]) = (_musicList[rank], _musicList[rank - 1]);
                rank++;
            }
            rank = 0;
        }

        musicList = _musicList;
        if (music.validBallot == 0) musicList.pop();
        user.stakeRank = rank;

        gomToken.transfer(msg.sender, backNumber);

        emit BackVote(msg.sender, musicID, backNumber);
    }

    function backBlackball(uint256 musicID, uint256 backNumber) lock public {
        MusicInfo storage music = musicInfo[musicID];
        UserInfo storage user = userInfo[musicID][msg.sender];

        require(user.dislikeVoteNumber >= backNumber, "Blackballed number is not enough.");

        music.dislikeBallot = music.dislikeBallot.sub(backNumber);

        uint256[] memory _musicList = musicList;

        uint256 rank;

        if (music.onMusicList) {
            music.validBallot = music.validBallot.add(backNumber);
            //sort music
            for (uint256 i = 0; i < _musicList.length; i++) {
                //Get the rank of music before ranking.
                if (_musicList[i] == musicID) {
                    rank = i + 1;
                    break;
                }
            }
            while (rank > 1) {
                if (music.validBallot > musicInfo[_musicList[rank - 2]].validBallot) {
                    (_musicList[rank - 1], _musicList[rank - 2]) = (_musicList[rank - 2], _musicList[rank - 1]);
                    rank--;
                } else {
                    break;
                }
            }
        } else {
            if (music.likeBallot > music.dislikeBallot) {
                music.validBallot = music.likeBallot.sub(music.dislikeBallot);
            }
            if (music.validBallot > 0 && _musicList.length < lengthLimit) {
                //add one music to the music list
                musicList.push(musicID);
                _musicList = musicList;
                music.onMusicList = true;
                rank = _musicList.length;

                while (rank > 1) {
                    if (music.validBallot > musicInfo[_musicList[rank - 2]].validBallot) {
                        (_musicList[rank - 1], _musicList[rank - 2]) = (_musicList[rank - 2], _musicList[rank - 1]);
                        rank--;
                    } else {
                        break;
                    }
                }
            } else if (music.validBallot > musicInfo[_musicList[_musicList.length - 1]].validBallot) {
                //replace the music of the last bank
                musicInfo[_musicList[_musicList.length - 1]].onMusicList = false;
                music.onMusicList = true;
                _musicList[_musicList.length - 1] = musicID;
                rank = _musicList.length;

                while (rank > 1) {
                    if (music.validBallot > musicInfo[_musicList[rank - 2]].validBallot) {
                        (_musicList[rank - 1], _musicList[rank - 2]) = (_musicList[rank - 2], _musicList[rank - 1]);
                        rank--;
                    } else {
                        break;
                    }
                }
            }
        }

        musicList = _musicList;
        user.dislikeVoteNumber = user.dislikeVoteNumber.sub(backNumber);
        user.stakeTime = block.timestamp;
        user.stakeRank = rank;

        gomToken.transfer(msg.sender, backNumber);

        emit BackBlackball(msg.sender, musicID, backNumber);
    }

    function _claimReward(uint256 musicIDBefore, address userAddress) internal {
        uint256 musicRank;
        for (uint256 i = 0; i < musicList.length; i++) {
            if (musicList[i] == musicIDBefore) {
                musicRank = i + 1;
                break;
            }
        }

        UserInfo memory userBefore = userInfo[musicIDBefore][userAddress];

        uint256 rewardAmount;
        uint256 stakePeriod;
        uint256 userBaseTime = userBefore.stakeTime;

        if (startTime == 0 || clacBaseTime == 0) return;

        if (userBaseTime < startTime) {
            userBaseTime = startTime;
        }

        if (block.timestamp > userBaseTime) {
            stakePeriod = block.timestamp - userBaseTime;
        }

        uint256 baseNo = userBaseTime.sub(clacBaseTime);

        if (stakePeriod > 0 && userBefore.likeVoteNumber > 0) {
            rewardAmount = userBefore.likeVoteNumber.mul(stakePeriod).div(baseNo);
            uint256 rankUp;
            if (musicRank > 0) {
                if (userBefore.stakeRank == 0) {
                    rankUp = uint256(201).sub(musicRank);
                } else if (userBefore.stakeRank > musicRank) {
                    rankUp = userBefore.stakeRank.sub(musicRank);
                }
            }
            if (rankUp > 0) rewardAmount += rewardAmount.mul(rankUp).div(upBase);

            gomToken.mint(userAddress, rewardAmount);
            gomToken.mint(teamPool, rewardAmount.mul(4).div(10));
            gomToken.mint(addedPool, rewardAmount.div(10));

            emit VoteReward(userAddress, rewardAmount, rewardAmount.mul(4).div(10), rewardAmount.div(10));
        }
        if (stakePeriod > 0 && userBefore.dislikeVoteNumber > 0) {
            rewardAmount = userBefore.dislikeVoteNumber.mul(stakePeriod).div(baseNo);
            uint256 rankDown;
            if (userBefore.stakeRank > 0) {
                if (musicRank == 0) {
                    rankDown = uint256(201).sub(userBefore.stakeRank);
                } else if (userBefore.stakeRank < musicRank) {
                    rankDown = musicRank.sub(userBefore.stakeRank);
                }
            }
            if (rankDown > 0) rewardAmount += rewardAmount.mul(rankDown).div(upBase);

            gomToken.mint(userAddress, rewardAmount);
            gomToken.mint(teamPool, rewardAmount.mul(4).div(10));
            gomToken.mint(addedPool, rewardAmount.div(10));

            emit BlackballReward(userAddress, rewardAmount, rewardAmount.mul(4).div(10), rewardAmount.div(10));
        }
    }

    /*function testMint(uint256 rewardAmount) public {
        gomToken.mint(msg.sender, rewardAmount);
    }*/

    function likeReward(uint256 musicID, address userAddress) public view returns (uint256) {
        if (startTime == 0 || clacBaseTime == 0) return uint256(0);

        uint256 musicRank;
        for (uint256 i = 0; i < musicList.length; i++) {
            if (musicList[i] == musicID) {
                musicRank = i + 1;
                break;
            }
        }

        UserInfo memory userBefore = userInfo[musicID][userAddress];

        uint256 rewardAmount;
        uint256 stakePeriod;
        uint256 userBaseTime = userBefore.stakeTime;

        if (userBaseTime < startTime) {
            userBaseTime = startTime;
        }

        if (block.timestamp > userBaseTime) {
            stakePeriod = block.timestamp - userBaseTime;
        }

        uint256 baseNo = userBaseTime.sub(clacBaseTime);

        if (stakePeriod > 0 && userBefore.likeVoteNumber > 0) {
            rewardAmount = userBefore.likeVoteNumber.mul(stakePeriod).div(baseNo);
            uint256 rankUp;
            if (musicRank > 0) {
                if (userBefore.stakeRank == 0) {
                    rankUp = uint256(201).sub(musicRank);
                } else if (userBefore.stakeRank > musicRank) {
                    rankUp = userBefore.stakeRank.sub(musicRank);
                }
            }
            if (rankUp > 0) rewardAmount += rewardAmount.mul(rankUp).div(upBase);
        }

        return rewardAmount;
    }

    function dislikeReward(uint256 musicID, address userAddress) public view returns (uint256) {
        if (startTime == 0 || clacBaseTime == 0) return uint256(0);

        uint256 musicRank;
        for (uint256 i = 0; i < musicList.length; i++) {
            if (musicList[i] == musicID) {
                musicRank = i + 1;
                break;
            }
        }

        UserInfo memory userBefore = userInfo[musicID][userAddress];

        uint256 rewardAmount;
        uint256 stakePeriod;
        uint256 userBaseTime = userBefore.stakeTime;

        if (userBaseTime < startTime) {
            userBaseTime = startTime;
        }

        if (block.timestamp > userBaseTime) {
            stakePeriod = block.timestamp - userBaseTime;
        }

        uint256 baseNo = userBaseTime.sub(clacBaseTime);

        if (stakePeriod > 0 && userBefore.dislikeVoteNumber > 0) {
            rewardAmount = userBefore.dislikeVoteNumber.mul(stakePeriod).div(baseNo);
            uint256 rankDown;
            if (userBefore.stakeRank > 0) {
                if (musicRank == 0) {
                    rankDown = uint256(201).sub(userBefore.stakeRank);
                } else if (userBefore.stakeRank < musicRank) {
                    rankDown = musicRank.sub(userBefore.stakeRank);
                }
            }
            if (rankDown > 0) rewardAmount += rewardAmount.mul(rankDown).div(upBase);
        }

        return rewardAmount;
    }

    function getMusicListInfo() public view returns (uint256[] memory) {
        uint256[] memory _musicList = musicList;
        return _musicList;
    }

    function setStartTime(uint256 _startTime) public onlyOwner() {
        startTime = _startTime;
    }

    function setClacBaseTime(uint256 _clacBaseTime) public onlyOwner() {
        clacBaseTime = _clacBaseTime;
    }

    function setPoolAddress(address _teamPool, address _addedPool) public onlyOwner() {
        teamPool = _teamPool;
        addedPool = _addedPool;
    }

    function setLengthLimit(uint256 _lengthLimit) public onlyOwner() {
        lengthLimit = _lengthLimit;
    }

    function setUpBase(uint256 _upBase) public onlyOwner() {
        upBase = _upBase;
    }

    function setContract(IGOMTOKEN _gomToken, IGSOUND _godSound) public onlyOwner() {
        gomToken = _gomToken;
        godSound = _godSound;
    }

}