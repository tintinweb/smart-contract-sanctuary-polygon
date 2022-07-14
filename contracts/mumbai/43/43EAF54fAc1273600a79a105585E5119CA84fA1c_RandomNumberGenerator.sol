//  SPDX-License-Identifier: None
pragma solidity ^0.8.0;

contract RandomNumberGenerator {
    uint256 public globalNonce;
    mapping(address => uint256) public nonces;

    event Numbers(
        address indexed caller,
        uint256 indexed gameId,
        uint256 dice1,
        uint256 dice2,
        uint256 dice3
    );

    constructor() {
        globalNonce = block.timestamp % 113;
    }

    function generate(
        uint256 gameId,
        uint256 uNum,
        uint256 sNum,
        bytes calldata uPhrases,
        bytes calldata sPhrases
    )
        external
        returns (
            uint256 _dice1,
            uint256 _dice2,
            uint256 _dice3
        )
    {
        uint256 _globalNonce = globalNonce + 1;
        uint256 _nonce = nonces[msg.sender] + 1;

        bytes[7] memory _data;

        if (_globalNonce % 3 == 0) {
            _data = [
                _numberToBytes(uNum),
                _numberToBytes(sNum),
                _numberToBytes(block.number),
                _numberToBytes(block.timestamp),
                uPhrases,
                sPhrases,
                _numberToBytes(_globalNonce)
            ];

            (_dice1, _dice2, _dice3) = _generateBases(
                _globalNonce,
                _nonce,
                0,
                _data
            );
            (_dice1, _dice2, _dice3) = _random(_dice1, _dice2, _dice3);
        } else if (_globalNonce % 3 == 1) {
            _data = [
                uPhrases,
                sPhrases,
                _numberToBytes(_nonce),
                _numberToBytes(uNum),
                _numberToBytes(sNum),
                _numberToBytes(block.number),
                _numberToBytes(block.timestamp)
            ];

            (_dice1, _dice2, _dice3) = _generateBases(
                _globalNonce,
                _nonce,
                1,
                _data
            );
            (_dice1, _dice2, _dice3) = _random(_dice1, _dice2, _dice3);
        } else {
            _data = [
                _numberToBytes(block.number),
                _numberToBytes(block.timestamp),
                _numberToBytes(uNum),
                _numberToBytes(sNum),
                _numberToBytes(_nonce),
                uPhrases,
                sPhrases
            ];

            (_dice1, _dice2, _dice3) = _generateBases(
                _globalNonce,
                _nonce,
                2,
                _data
            );
            (_dice1, _dice2, _dice3) = _random(_dice1, _dice2, _dice3);
        }
        nonces[msg.sender] = _nonce;
        globalNonce = _globalNonce;

        emit Numbers(msg.sender, gameId, _dice1, _dice2, _dice3);
        return (_dice1, _dice2, _dice3);
    }

    function _numberToBytes(uint256 _num)
        private
        pure
        returns (bytes memory b)
    {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), _num)
        }
    }

    function _generateBases(
        uint256 _globalNonce,
        uint256 _nonce,
        uint256 _opt,
        bytes[7] memory _seed
    )
        private
        pure
        returns (
            uint256 _bigNum1,
            uint256 _bigNum2,
            uint256 _bigNum3
        )
    {
        if (_opt == 0) {
            _bigNum1 = _generateNumBer(_globalNonce, _seed);
            _bigNum2 = _generateNumBer(_globalNonce - _nonce, _seed);
            _bigNum3 = _generateNumBer(_globalNonce + _nonce, _seed);
        } else if (_opt == 1) {
            _bigNum1 = _generateNumBer(_nonce, _seed);
            _bigNum2 = _generateNumBer(_globalNonce, _seed);
            _bigNum3 = _generateNumBer(_globalNonce - _nonce, _seed);
        } else {
            _bigNum1 = _generateNumBer(_nonce, _seed);
            _bigNum2 = _generateNumBer(_globalNonce, _seed);
            _bigNum3 = _generateNumBer(_globalNonce + _nonce, _seed);
        }
    }

    function _generateNumBer(uint256 _pos, bytes[7] memory _seed)
        private
        pure
        returns (uint256 _bignum)
    {
        _pos = _pos % 7;

        bytes memory temp;
        for (uint256 i = _pos; i < 7; ) {
            temp = abi.encodePacked(temp, _seed[i]);
            if (_pos != 0 && i == 6) i = 0;
            else if (_pos != 0 && i == _pos - 1) break;
            else i++;
        }

        _bignum = uint256(keccak256(temp));
    }

    function _random(
        uint256 _base1,
        uint256 _base2,
        uint256 _base3
    )
        private
        view
        returns (
            uint256 _dice1,
            uint256 _dice2,
            uint256 _dice3
        )
    {
        uint256 _num = block.timestamp * block.number;
        uint256[7] memory _primes1 = [uint256(3), 5, 7, 11, 13, 17, 19];
        uint256[11] memory _primes2 = [
            uint256(10949),
            10181,
            11551,
            10301,
            118081,
            11177,
            10069,
            10909,
            10333,
            11927,
            11117
        ];

        _num *= _num;

        _dice1 = _filter(
            _base1,
            ((_num % 10000000019) % 1000003) % 59,
            ((_num % 10000000069) % 1000039) % 11
        );
        _dice2 = _filter(
            _base2,
            ((_num % 10000000033) % 1000033) % 59,
            ((_num % 10000000097) % 1000081) % 11
        );
        _dice3 = _filter(
            _base3,
            ((_num % 10000000061) % 1000037) % 59,
            ((_num % 10000000103) % 1000099) % 11
        );

        _dice1 =
            ((_randDistribution(
                _primes2[_dice1 % 11],
                (_dice1 % 1000003) % _primes2[_dice1 % 11]
            ) + _primes1[_dice1 % 7]) % 7) +
            1;
        _dice2 =
            ((_randDistribution(
                _primes2[_dice2 % 11],
                (_dice2 % 1000033) % _primes2[_dice2 % 11]
            ) + _primes1[_dice2 % 7]) % 7) +
            1;
        _dice3 =
            ((_randDistribution(
                _primes2[_dice3 % 11],
                (_dice3 % 1000037) % _primes2[_dice3 % 11]
            ) + _primes1[_dice3 % 7]) % 7) +
            1;
    }

    function _filter(
        uint256 _base,
        uint256 _pos,
        uint256 _length
    ) private pure returns (uint256 _num) {
        _num = (_base / 10**_pos) % 10**_length;
    }

    function _randDistribution(uint256 _sample, uint256 _value)
        private
        pure
        returns (uint256)
    {
        uint256 _range = _sample / 7;
        if (_value < _range)
            if (_value < _range / 2) return _leftSide(_range / 2, _value);
            else return _leftSide(_range / 2, _value);
        else if (_value >= _range && _value < 2 * _range)
            if (_value < (3 * _range) / 2)
                return _leftSide((3 * _range) / 2, _value);
            else return _rightSide((3 * _range) / 2, _value);
        else if (_value >= 2 * _range && _value < 3 * _range)
            if (_value < (5 * _range) / 2)
                return _leftSide((5 * _range) / 2, _value);
            else return _rightSide((5 * _range) / 2, _value);
        else if (_value >= 3 * _range && _value < 4 * _range)
            if (_value < (7 * _range) / 2)
                return _leftSide((7 * _range) / 2, _value);
            else return _rightSide((7 * _range) / 2, _value);
        else if (_value >= 4 * _range && _value < 5 * _range)
            if (_value < (9 * _range) / 2)
                return _leftSide((9 * _range) / 2, _value);
            else return _rightSide((9 * _range) / 2, _value);
        else if (_value >= 5 * _range && _value < 6 * _range)
            if (_value < (11 * _range) / 2)
                return _leftSide((11 * _range) / 2, _value);
            else return _rightSide((11 * _range) / 2, _value);
        else if (_value < (13 * _range) / 2)
            return _leftSide((13 * _range) / 2, _value);
        else return _rightSide((13 * _range) / 2, _value);
    }

    function _leftSide(uint256 _sample, uint256 _value)
        private
        pure
        returns (uint256)
    {
        uint256 _percent = _sample / 100;
        if (_value >= (100 - 30) * _percent && _value <= _sample) return 1;
        else if (
            _value >= (100 - 55) * _percent && _value < (100 - 30) * _percent
        ) return 2;
        else if (
            _value >= (100 - 70) * _percent && _value < (100 - 55) * _percent
        ) return 3;
        else if (
            _value >= (100 - 82) * _percent && _value < (100 - 70) * _percent
        ) return 4;
        else if (
            _value >= (100 - 91) * _percent && _value < (100 - 82) * _percent
        ) return 5;
        else if (
            _value >= (100 - 97) * _percent && _value < (100 - 91) * _percent
        ) return 6;
        else return 7;
    }

    function _rightSide(uint256 _sample, uint256 _value)
        private
        pure
        returns (uint256)
    {
        uint256 _percent = _sample / 100;
        if (_value <= 30 * _percent && _value >= _sample) return 1;
        else if (_value <= 55 * _percent && _value > 30 * _percent) return 2;
        else if (_value <= 70 * _percent && _value > 55 * _percent) return 3;
        else if (_value <= 82 * _percent && _value > 70 * _percent) return 4;
        else if (_value <= 91 * _percent && _value > 82 * _percent) return 5;
        else if (_value <= 97 * _percent && _value > 91 * _percent) return 6;
        else return 7;
    }
}