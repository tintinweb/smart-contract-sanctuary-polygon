// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Art {
    struct Trait {
        bytes32 traitId;
        string name;
        string ipfs;
        uint16 rarity;
    }

    struct ArtStore {
        Trait[] bg;
        Trait[] body;
        Trait[] hair;
        Trait[] eyes;
        Trait[] accsBody;
        Trait[] accsFace;
        Trait[] hat;
    }

    ArtStore internal art;

    constructor () {
        art.bg.push(Trait("background", "Multichain", "QmYnjkZgM5NFTsS3uubt46vZq3pkWWUSZuDWxE2ufcpMxC", 4));
        art.bg.push(Trait("background", "Moon", "QmPMPYM8dbHbmhz1HhMxjqhyYjFoyL4AV9vGiuBSMWfng6", 4));
        art.bg.push(Trait("background", "Pastures", "QmWNTT1pn1kYCKWC7fFNPzNa6dc6rq3zAMngU4ZPNVrxEC", 8));
        art.bg.push(Trait("background", "Psychedelic", "QmXf7znngpixoQ2ZuRnmidtcqwJPs7Pu5zToKo7yZoWFtj", 20));
        art.bg.push(Trait("background", "Snow", "Qmcr57vWi2hxMRtgCbAGodyQosK4phbpKsUb34aL6cdgjo", 20));
        art.bg.push(Trait("background", "Beach", "QmamWxMQ85YQHhohNQonRdhN7jaYyj1L644Ug8Kq2SLvea", 20));
        art.bg.push(Trait("background", "Ethereum", "QmebRDUCERUdUGD2TCquXji8k4n9XiB9KW8E3y7bnaih4R", 28));
        art.bg.push(Trait("background", "Moonriver", "QmNh8pmaccg9nUXBPAvyghGdgW82ptMwMbUnJy2LVbXjhA", 32));
        art.bg.push(Trait("background", "Celo", "QmeE8j2VFizW6paXF5bYdsXHiLFRkoWM7x1iMXUYfnBerU", 32));
        art.bg.push(Trait("background", "BSC", "QmS9aJutAiuonqHpgemFq4KSHvMS7R3D7KYNFJ2ZuayXuK", 42));
        art.bg.push(Trait("background", "Fantom", "QmQd5mNttnPA2USEGKaNdukyo2rqwsG4NFXtEx3N1TjXnh", 42));
        art.bg.push(Trait("background", "Polygon", "QmPHWNKi4WRuE7U5xamvbNknUtXmDRBymeyWYzWLBoz4tW", 42));
        art.bg.push(Trait("background", "Arbitrum", "QmS61BXRdY5C3MZeHr6YfWcANBaisz6d3CARdvmvkqYHev", 42));
        art.bg.push(Trait("background", "Avalanche", "QmSKjkrcMJeZx6c9yjWZz3tHNqfwiQwgkvMP5ae7m6BjRa", 58));
        art.bg.push(Trait("background", "Harmony", "QmYYU4pCnZEcQ7s5n6Rwt8oyYzX1QNiJHkPAzU3oC7ghjb", 58));
        art.bg.push(Trait("background", "Heco", "QmSU96uhmqWajyhYvoytSH6T1mtNsCQxqQN6bbwr3geYx8", 58));
        art.bg.push(Trait("background", "Yellow", "Qmd1V9i2noHuMU1VBSrHW1dKCPfwLf7NrVLcRqMYDhM9EM", 78));
        art.bg.push(Trait("background", "Purple", "QmYKBwRJew6rgLXQibwzatBsnYji4NAx1oQNim6nBhoN66", 78));
        art.bg.push(Trait("background", "Red", "QmVy3kejLwDS5vyRaJL9CZEZTesWJJidJDeCB1y6LmUEJ9", 78));
        art.bg.push(Trait("background", "Blue", "QmSaLTDRguvE8n1HEjD31yEaeXGYJJYLN9MNXmPSu9oG9h", 78));
        art.bg.push(Trait("background", "Green", "QmQzTmoinbrqqnDWb14YP3U6UHQxR4AEkPke8Kkw4GRZhr", 78));
        art.bg.push(Trait("background", "None", "", 100));

        art.body.push(Trait("body", "BDSM", "QmcXKShGh77Pxb5tofqC3qptzNDbqcMDb6AKPveX76pCPp", 4));
        art.body.push(Trait("body", "Farmer", "QmNSpmFCHaS8NBwrV6daec4ozMXE86pTcAeChS34D1Ln3k", 4));
        art.body.push(Trait("body", "Armored cow", "QmYcJuxSaYXEv1fVP2Yr2MQucFrTZoCeTqaFazRgo5secU", 4));
        art.body.push(Trait("body", "Cyborg skin", "QmR3Tkb8tzSPhpweRQBbtXSkt9ovWjkHCDm9W3UvmnKHjz", 4));
        art.body.push(Trait("body", "Black suit", "QmYXH9sg6vp7B8fCUw3PJAUqvJKXdVGBsMskKV9Tp4GQ1W", 4));
        art.body.push(Trait("body", "Alien", "QmNeM6WeLmdQV2XdeBhpfkpYeQT7SKXChDKGiX7nDoPHdQ", 15));
        art.body.push(Trait("body", "Zombie", "QmaJeoZf5bJTETr4qXLXErviUiK8CQP1RYwAHrQwCsn2ra", 23));
        art.body.push(Trait("body", "Ziggy", "QmVdvTDozaBDwYXJySN2PL7G1mcjJzqfDAfUg1WdMe95kJ", 23));
        art.body.push(Trait("body", "Chicken suit", "QmfRN7i9Cb3WYmYBDwwYBvFm5p6ZZorjqnroqXMxsgqwyp", 23));
        art.body.push(Trait("body", "Hawai shirt", "QmaH4Ra2szcAnHTK5RGkN1Ft7G5oQeFNnAB72odsrhQWjK", 46));
        art.body.push(Trait("body", "Cowboy suit", "QmdkBmw1dfPKqBdmWBzCEV777LXYKMDU4wT2YsqYL8AKHA", 46));
        art.body.push(Trait("body", "Blue jacket", "QmS6d9WCyzhZrX9Chq6ZHQGEt8Lnkxh5e3LTH2VeF9qQdV", 46));
        art.body.push(Trait("body", "Ethereum", "QmVxwWZKRhoXYfHD6ZSFt2m5d8xkuBzxQ15saHbJ2aPyC6", 59));
        art.body.push(Trait("body", "Polygon", "QmdGZwekGVimg7a44Mw1g8FFVQ2YLSwZeDj6kTxvMa6Z8R", 59));
        art.body.push(Trait("body", "Fantom", "QmeyCehW4JnxtPvWbHknoGb84ZS5ojUgFr1aQwHvGek2fS", 59));
        art.body.push(Trait("body", "BSC", "QmU6MfyYkoC3XfBAxNkWtLPs9NgHdt7uFvCZQBEbz53DKh", 59));
        art.body.push(Trait("body", "Moonriver", "QmWW1XpnQ8pbvFQAURtKsbnq8szFr71dr2LDMmWiouspsq", 59));
        art.body.push(Trait("body", "Celo", "QmZj6U4ESUSU1PfEJmG7QG8CWEKRkwtAkhX48cdguGDhue", 59));
        art.body.push(Trait("body", "Avalanche", "QmXi6ZP5EkwXT4kVzVWmAwNQRRw8HARV691WvURZv5cWNr", 59));
        art.body.push(Trait("body", "Arbitrum", "QmUxmTN5FZQqGm4yUdxXf1eU24Wqq8kfimvrQ1WZLrKXzD", 59));
        art.body.push(Trait("body", "Harmony", "QmRCi8kF4d68demLvxvNkXseRG5MrhpP8W5bsJSPgo4Zj6", 59));
        art.body.push(Trait("body", "Heco", "QmT34Qwb9KR9MP1vJENzUyCGYTjk5FhQd8VxfWirfavmmK", 59));
        art.body.push(Trait("body", "Blue sweater", "QmUmacVtnUAwzQ9ds9ZaJdsQD6EDYP6FxPYgLnjHpkGkbJ", 66));
        art.body.push(Trait("body", "Default Base", "QmWL5kc3ULxDbdGndBAjatNPi36PhQyNiq9VAbkkmDnACP", 102));

        art.eyes.push(Trait("eyes", "Pleading eyes", "QmUBfyUNipDg8wij5xSDbctueQB3CpzQGWw1oH8kw2sg7v", 50));
        art.eyes.push(Trait("eyes", "Anime eyes", "QmXqDs8yYTr8Lpg4shJrJH8hFjjX7kVVT3jGpE1V6q22Hm", 50));
        art.eyes.push(Trait("eyes", "Tired eyes", "QmTJHVcYCbMYTNzKsiQyNfx6uCKB3GgtFocNTxwvVpJjxG", 50));
        art.eyes.push(Trait("eyes", "Normal eyes", "QmQ8y27FUUS4PjtyMWpLwFq3YRJougLV7LFXsZNdWah2Fa", 850));

        art.accsFace.push(Trait("accsFace", "Rayban sunglasses gold", "QmetexU9n555iV3HVwqxtfKLTVNJXGQdjj52DvQ5vafHrX", 3));
        art.accsFace.push(Trait("accsFace", "Laser eyes gold", "QmT13V1XGzusK7RZDZWB1TtKibX9j624ht3dVkFGA4paVJ", 3));
        art.accsFace.push(Trait("accsFace", "Cuban cigar gold", "QmPRg5UrTWUuADposUqUtUdJwKVfm7ee1EakKr28vWZgAn", 7));
        art.accsFace.push(Trait("accsFace", "Spliff gold", "QmeyayjdHzZFFUaKFKzcrFxSTiHqNfX33Q8NEgHS6pAxu8", 7));
        art.accsFace.push(Trait("accsFace", "Laser eyes", "QmcsXcVuJCp5JRw7eragpuw5WrzTbySpUVZvaJxfQd6GhD", 11));
        art.accsFace.push(Trait("accsFace", "Left ear two rings gold","QmUH8cyi9qqWGrk1gYUKzMzrkLTSmJN8mBrBwLH4PEdH4f", 11));
        art.accsFace.push(Trait("accsFace", "Monocle gold", "QmXqHKSqJj3qBVZ1aN8pfhBnwm8JmqLvTpzidpLPGnB1cg", 11));
        art.accsFace.push(Trait("accsFace", "Rayban sunglasses", "QmXNwbCLH2JR4gYM4EVRjGyEkPWKQQWDKTjdYRXbEPSP7U", 15));
        art.accsFace.push(Trait("accsFace", "Cuban cigar", "QmZ9GfYw1coDtaDViTUXZDZb836RrGH2mnLrGexFi2vnHN", 15));
        art.accsFace.push(Trait("accsFace", "Pirate eye patch gold", "QmXR5xWYpKB4kkXeCP2Hm3P9Y3Ygh5Eo1cYsPrHc8DKJws", 19));
        art.accsFace.push(Trait("accsFace", "Spliff", "QmR7rAAC5g3WYE89bkTVjFi3wf3KA9goPrZRynGSxGMhM5", 27));
        art.accsFace.push(Trait("accsFace", "Aviator sunglasses gold", "QmWVM9ksMdYaKrss88dTHmNEFuHhtrZPqD3qbgMwyKqP43", 27));
        art.accsFace.push(Trait("accsFace", "Earrings each ear gold", "QmerJ992cLzRxN1AQzV1EzEy7AeqZMzbYRnMtGYGqvQatM", 27));
        art.accsFace.push(Trait("accsFace", "Left ear two rings", "QmaMa1LUx7uxwGfRiRKENrg6jkDfjmz7eha5msU9iShQWc", 27));
        art.accsFace.push(Trait("accsFace", "Monocle", "QmYpFgDKQet4ewLEq7n6PGzUH8ZH4VFb8nE2bYj3rbyBai", 27));
        art.accsFace.push(Trait("accsFace", "Pirate eye patch", "QmU88fXziJWNpj4t9UFHVs9Vcvu32zyzoJB7wfyqE1Jbno", 27));
        art.accsFace.push(Trait("accsFace", "Pipe gold", "QmdZW284ozSxnxpLLDhCFxN55Pqa3VYnSXkFX4abbf7TrL", 40));
        art.accsFace.push(Trait("accsFace", "Aviator blue sunglasses", "QmT9G2MZYetbvttkdQ2w69ygcKR3VrPhxqixc2Vr5W58Q3", 47));
        art.accsFace.push(Trait("accsFace", "Left ear one ring gold", "Qmab754zAgfa7iYzpQjLDCa7ZVSouVobUffAvtYc44JzXK", 47));
        art.accsFace.push(Trait("accsFace", "Earrings each ear", "Qme8p43CSjunYBVtGLnWD3V8JLj9HomQiVak7eC73Nu5zu", 60));
        art.accsFace.push(Trait("accsFace", "Multichain earring gold", "Qmf3fgwUmGkXtMfi85SPnAeywdNmMyjbRUDMt8Ksch579z", 75));
        art.accsFace.push(Trait("accsFace", "Pipe", "QmezF7KzACTnnHRXAA39dn1A8vAS9A6ap2fqYD9ETW88Nd", 80));
        art.accsFace.push(Trait("accsFace", "Left ear one ring", "QmQKdYGckm33DrYyHWe1X7iEe2nP2mC39yonSNSpUvQpr5", 97));
        art.accsFace.push(Trait("accsFace", "Multichain earring", "QmU94afJao9FnT2jMNPTh6y2zyhfKzJAiKn1s7wsBLekYT", 140));
        art.accsFace.push(Trait("accsFace", "None", "", 150));

        art.accsBody.push(Trait("accsBody", "BIFI maxi necklace gold", "QmRf3PUk3Suyg6pKs2BwRzs8FtsusvBVu1J173UsqKygWo", 11));
        art.accsBody.push(Trait("accsBody", "SAFU necklace gold", "QmRGSw4m9tjU8iJ1mWnyE8WGvgVRcSqehfimFiSknHR1EG", 11));
        art.accsBody.push(Trait("accsBody", "BIFI maxi necklace", "QmWb1RSRGtf1NFWE6P9nx8xG7LintsMvz6fXdTkqqnTbeA", 31));
        art.accsBody.push(Trait("accsBody", "SAFU necklace", "QmZ5DKK6GGisqL3KvvinaUTiJFzeNzpdrLpoKXUbDMrgaL", 31));
        art.accsBody.push(Trait("accsBody", "'This is fine' necklace gold", "QmWUCcrE11QaJ5fjg5UbZTWkNXwwPVbb5xCRmBEwAno4RM", 35));
        art.accsBody.push(Trait("accsBody", "Presidential sash gold", "QmZ3Ag3ty71RZQcXJrNE5ZXBJnki7yydBTkJ1Li56CpkdY", 35));
        art.accsBody.push(Trait("accsBody", "Vault key gold", "Qmf4bxovQxgFdYXxkLroSnJW1pRnT6qpiWfqcZW2eW1P5w", 46));
        art.accsBody.push(Trait("accsBody", "Presidential sash", "QmV7imP7VuehSN7W1yghNHkYK9LYPopff6MA8k1iff5rEW", 70));
        art.accsBody.push(Trait("accsBody", "'This is fine' necklace", "QmTa2nygb2mvgtrcY4skLeACVQQhGgT51rL1tRzyRo4jJ6", 70));
        art.accsBody.push(Trait("accsBody", "Moo necklace gold", "QmeUjuy5rodvqW54AoaW8ypvzuesSkqMhoXFkLQiZBWpnZ", 75));
        art.accsBody.push(Trait("accsBody", "Farmer pitchfork gold", "QmcS7aUkP53eQmPAidvvVwXWQa8ic3wH4Bzf3ayuT8yyAN", 75));
        art.accsBody.push(Trait("accsBody", "Vault key", "QmNp9ZR3jVjPvKhkw3zSCzdTDSHgRBMzoaVquC34X65SVb", 121));
        art.accsBody.push(Trait("accsBody", "Moo necklace", "QmSRHG5wq8rTnfAaWHui9A5Qyb8tXmZ6aGoA32DjCAmAr7", 121));
        art.accsBody.push(Trait("accsBody", "Farmer pitchfork", "QmTCiRjQNYHF4x7zsELEKV51RZfx8SJyGtFr7dVDFTDGUu", 148));
        art.accsBody.push(Trait("accsBody", "None", "", 120));

        art.hair.push(Trait("hair", "Mohawk hair", "QmWxn9aTmpghw8y8umg3QTdtqwyHgg3mMhefVmGmTnCmit", 7));
        art.hair.push(Trait("hair", "Rasta hair", "QmZ8Sjf4qaR3gSLiSUkAu67edNhZvba2xh8yXz626qP2BJ", 15));
        art.hair.push(Trait("hair", "Short hair", "QmQ4vQw72w3yRzwFWft9icnVtkujJNAWCRCkSeQByxVBM3", 28));
        art.hair.push(Trait("hair", "Cow wig", "QmNuMUfiTYNnJ3oD9h7FWJNr9mpZeoP8mV7tU6s3G1myXV", 28));
        art.hair.push(Trait("hair", "Mr. T hair", "Qmaj4VPh3rLzraAgZwGJbANkJTsqodFtna65YN1y8LJcm7", 28));
        art.hair.push(Trait("hair", "None", "", 894));

        art.hat.push(Trait("hat", "Ethereum rainbow golden hat", "QmTJJxeCs5axSNDwtkvzLKcNVKerV14ARuv32BahpJXDJH", 10));
        art.hat.push(Trait("hat", "Top hat golden", "QmaSAdvSQL6HjmZgtbaWdajcy3R4sMg2VGBj4nCuXEfoDR", 10));
        art.hat.push(Trait("hat", "Cowboy golden hat", "QmPRuoKdNaa5Qa3pGGpZtojsoFUEtXEVCj5URxe73qrZ84", 11));
        art.hat.push(Trait("hat", "Straw golden hat", "QmS4MgKgLGJMsnPyZAed9f1C53FwcTB3zQo5nrxoVMip1i", 11));
        art.hat.push(Trait("hat", "Celo golden hat", "QmZSaUYd9iM34cSbjXcXkrZzQFj2C2ZRahhHEPwnWEi8ZY", 20));
        art.hat.push(Trait("hat", "Moonriver golden hat", "QmZFg5xBaSqHWsBW92qiv8epkPSExzBzKJzsRdrVk6XXW3", 20));
        art.hat.push(Trait("hat", "BSC golden hat", "QmPxGYW8VemNXLbRGBifirnutthtEqRSJNeZsB2fBWfGHy", 20));
        art.hat.push(Trait("hat", "Polygon golden hat", "QmdYnLvUk18xsSnwGJ5oty4LTeM8djZ9bfrptEHyfGbpEz", 20));
        art.hat.push(Trait("hat", "Ethereum golden hat", "QmPydos5pHersHgpHMtfxWTzAJRQxUEUD8bTyu5TVZDA8B", 20));
        art.hat.push(Trait("hat", "Harmony golden hat", "QmcysPSdYcMzhzTvyY5bCT2uT3H5JXUREvthfHE9p9CTXF", 20));
        art.hat.push(Trait("hat", "Arbitrum golden hat", "QmWXAcJuqbgXXASycNYEg3TFK77G8h4zdE4rChsA7uyJQj", 20));
        art.hat.push(Trait("hat", "Fantom golden hat", "QmPfmUBbVfFJ8gYKXtQJAUQe2kysEjn5Cs69yaqNHx66t1", 20));
        art.hat.push(Trait("hat", "Avalanche golden hat", "QmXEkPsKc9wAqsyTikv3FF3wN9vznNJexwTvztb2ygpwzd", 20));
        art.hat.push(Trait("hat", "Heco golden hat", "QmbCkpLDVUjm4QhUEB6t5KJtz6dGALoUxq4PKVHL3AiFnK", 20));
        art.hat.push(Trait("hat", "Straw hat", "QmR8B1oy6X5vPPHbF5hhqQCXe3meSupQ7mNiFm8cDsMvoG", 27));
        art.hat.push(Trait("hat", "Cowboy hat", "QmVYBqmNeSm1YGEEwFjS3gfciQ8izPwuNDjHifsiT7nfm1", 27));
        art.hat.push(Trait("hat", "Top hat", "Qmf2VfEB4bHMHhwWBhxx6HjLAMA7t8LtMbmkpMnuZ173dH", 27));
        art.hat.push(Trait("hat", "Celo hat", "QmSNAS5rqTFowKQfm1z6hq5B5fq5pv4ZZ6CK3j8yPz5b8s", 47));
        art.hat.push(Trait("hat", "Moonriver hat", "QmYqRiQWYxYeNagqZH3g3rdDJG34zpgCCJKW7FRvxMMPjr", 47));
        art.hat.push(Trait("hat", "Ethereum rainbow hat", "QmephVnLvAr6gXxKkjMCwmnPJ7C33urdVr18ENXxSFEvTP", 47));
        art.hat.push(Trait("hat", "Fantom hat", "QmbpxcnfAPAivEhRqbQLk5Nz5PZXvQb1cvsuRaJTc4hMLP", 47));
        art.hat.push(Trait("hat", "Ethereum hat ", "QmQe9nPzUXYTHMmAJpjGje1D6bJW1xPDF11jXgQJKkYWzP", 47));
        art.hat.push(Trait("hat", "BSC hat", "QmbQvqSiTgfpjAhqendTkomaVECBh8uaKTRUq9NL75ubKe", 47));
        art.hat.push(Trait("hat", "Avalanche hat", "QmPgsFZ6NfCdQeUgJY3uMmKuTA1NGohqMHkWi7R6tT5un1", 47));
        art.hat.push(Trait("hat", "Polygon hat", "QmevhxAHEZDSus22zqsKPna16mcGdFQfmr8evQZmLh1uTM", 47));
        art.hat.push(Trait("hat", "Arbitrum hat", "QmaAdsJBDP6iajTwskypGvA5HPfReV2zZm8cw8624mw1YR", 47));
        art.hat.push(Trait("hat", "Harmony hat", "QmZKgEBXo7XZqAUWmbpp9JY4hr7PGFVdjXEhDgMs5Z6CyY", 47));
        art.hat.push(Trait("hat", "Heco hat", "QmRuY5HXTjWe8ruw8PMX7w7DV7G9nDa2cpSXNHHTYY7XZf", 47));
        art.hat.push(Trait("hat", "None", "", 160));
    }

    function cow(uint16[7] memory dna) public view returns (Trait[7] memory) {
        return [
            cowBackground(dna[0]),
            cowBody(dna[1]),
            cowHair(dna[2]),
            cowEyes(dna[3]),
            cowAccsBody(dna[4]),
            cowAccsFace(dna[5]),
            cowHat(dna[6])
        ];
    }

    function cowBackground(uint16 _gene) public view returns (Trait memory) {
        uint16 current = 0;

        for(uint16 i = 0; i < art.bg.length; i++) {
            current += art.bg[i].rarity;
            if (_gene <= current) {
                return art.bg[i];
            }
        }
    }

    function cowBody(uint16 _gene) public view returns (Trait memory) {
        uint16 current = 0;

        for(uint16 i = 0; i < art.body.length; i++) {
            current += art.body[i].rarity;
            if (_gene <= current) {
                return art.body[i];
            }
        }
    }

    function cowHair(uint16 _gene) public view returns (Trait memory) {
        uint16 current = 0;

        for(uint16 i = 0; i < art.hair.length; i++) {
            current += art.hair[i].rarity;
            if (_gene <= current) {
                return art.hair[i];
            }
        }
    }

    function cowEyes(uint16 _gene) public view returns (Trait memory) {
        uint16 current = 0;

        for(uint16 i = 0; i < art.eyes.length; i++) {
            current += art.eyes[i].rarity;
            if (_gene <= current) {
                return art.eyes[i];
            }
        }
    }

    function cowAccsBody(uint16 _gene) public view returns (Trait memory) {
        uint16 current = 0;

        for(uint16 i = 0; i < art.accsBody.length; i++) {
            current += art.accsBody[i].rarity;
            if (_gene <= current) {
                return art.accsBody[i];
            }
        }
    }

    function cowAccsFace(uint16 _gene) public view returns (Trait memory) {
        uint16 current = 0;

        for(uint16 i = 0; i < art.accsFace.length; i++) {
            current += art.accsFace[i].rarity;
            if (_gene <= current) {
                return art.accsFace[i];
            }
        }
    }

    function cowHat(uint16 _gene) public view returns (Trait memory) {
        uint16 current = 0;

        for(uint16 i = 0; i < art.hat.length; i++) {
            current += art.hat[i].rarity;
            if (_gene <= current) {
                return art.hat[i];
            }
        }
    }
}