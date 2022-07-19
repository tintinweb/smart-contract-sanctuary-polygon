// MC & MT
// www.mashu.dev

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Ownable {
    address private owner1 = 0x90faf98f2Dd9F7731C574A13d9CC626a8Fb018c1;
    address private owner2 = 0x19c11d5d1a61af975008e1F5Bb506740ec31FBA0;

    function getOwner1() public view returns (address) {
        return owner1;
    }
    function getOwner2() public view returns (address) {
        return owner2;
    }

    modifier onlyOwner() {
        require(msg.sender == owner1 || msg.sender == owner2 , "Not owner");
        _;
    }

    function setOwner1(address owner) public onlyOwner {
        owner1 = owner;
    }
    function setOwner2(address owner) public onlyOwner {
        owner2 = owner;
    }
}

contract CacciaAlTesoro is Ownable {

    bytes32[][] private answer;
    uint[] private startGame;
    uint private endGame;

    function setAnswer(string memory _answer, uint8 _game, uint8 _index) public onlyOwner {
        require(_game > 0, "Il primo gioco e' il numero: 1");
        require(_index > 0, "La prima domanda e' la numero: 1");

        _game =  _game-1;
        _index = _index-1;

        if (answer.length <= _game) {
            uint diff = _game - answer.length;
            for (uint i = 0; i <= diff; i++) {
                answer.push();
            }
        }

        if (answer[_game].length <= _index) {
            uint diff = _index - answer[_game].length;
            for (uint i = 0; i < diff; i++) {
                answer[_game].push();
            }
            return answer[_game].push(keccak256(abi.encodePacked(_answer)));
        }
        answer[_game][_index] = keccak256(abi.encodePacked(_answer));
    }
    function setStartGame(uint _timestamp, uint8 _game) public onlyOwner {
        require(_game > 0, "Il primo gioco e' il numero: 1");
        require(answer.length >= _game, "Devi creare prima il gioco per inserire una data di inizio");

        _game =  _game-1;

        if(startGame.length <= _game) {
            uint diff = _game - startGame.length;
            for (uint i = 0; i < diff; i++){
                startGame.push();
            }
            return startGame.push(_timestamp);
        }
    
        startGame[_game] = _timestamp;
    }
    function setEndGame(uint _timestamp) public onlyOwner {
        endGame = _timestamp;
    }

    function getAnswer(uint8 _game, uint8 _index) public view returns (bytes32) {
        require(_game > 0, "Il primo gioco e' il numero: 1");
        require(_index > 0, "La prima domanda e' la numero: 1");
        require(answer.length >= _game, "Il gioco selezionato non esiste");
        _game =  _game-1;
        require(answer[_game].length >= _index, "La domanda selezionata non esiste");
        _index = _index-1;
        return answer[_game][_index];
    }
    function getStartGame(uint8 _game) public view returns (uint) {
        require(_game > 0, "Il primo gioco e' il numero: 1");
        require(answer.length >= _game, "Il gioco selezionato non esiste");
        require(startGame.length >= _game, "Il gioco selezionato non ha un orario di inizio");
        _game =  _game-1;
        return startGame[_game];
    }
    function getEndGame() public view returns (uint) {
        require(endGame != 0, "Nessuna data di fine");
        return endGame;
    }
    function getAllAnswer(uint8 _game) public view returns (bytes32 [] memory) {
        require(_game > 0, "Il primo gioco e' il numero: 1");
        require(answer.length >= _game, "Il gioco selezionato non esiste");
        _game =  _game-1;
        return answer[_game];
    }
    function getAllStartGame() public view returns (uint [] memory) {
        return startGame;
    }

    function resetAnswer() public onlyOwner {
        for (uint i = 0; i < answer.length; i++){
            for (uint j = 0; j < answer[i].length; j++){
                delete answer[i][j];
            }
            delete answer[i];
        }
        delete answer;
    }
    function resetStartGame() public onlyOwner {
        for (uint i = 0; i < startGame.length; i++) {
            delete startGame[i];
        }
        delete startGame;
    }
    function resetEndGame() public onlyOwner {
        delete endGame;
    }
    function resetGame() public onlyOwner {
        for (uint i = 0; i < answer.length; i++){
            for (uint j = 0; j < answer[i].length; j++){
                delete answer[i][j];
            }
            delete answer[i];
        }
        delete answer;

        for (uint i = 0; i < startGame.length; i++) {
            delete startGame[i];
        }
        delete startGame;

        delete endGame;
    }

    function isCorrect(string memory _answer, uint8 _game, uint8 _index) public view returns (bool) {
        require(_game > 0, "Il primo gioco e' il numero: 1");
        require(_index > 0, "La prima domanda e' la numero: 1");
        require(answer.length >= _game, "Il gioco selezionato non esiste");
        require(startGame.length >= _game, "Il gioco selezionato non ha un orario di inizio");
        _game =  _game-1;
        require(answer[_game].length >= _index, "La domanda selezionata non esiste");
        _index = _index-1;
        require(endGame > block.timestamp, "Il gioco si e' concluso");
        require(startGame[_game] < block.timestamp, "Il gioco non e' ancora iniziato");

        return keccak256(abi.encodePacked(_answer)) == answer[_game][_index];
    }
}