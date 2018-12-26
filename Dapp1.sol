pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;
contract Main {
    enum teamRule { dictatorship, democratic, originator }  // maximum amount, subtotal everyone, who creat team
    gameConfig config;
    team[] teams;
    mapping(address => memberInfo) public addr2member;
    struct gameConfig {
        address developer;
        uint8 teamsCount;   // how many teams in currertRound
        uint8 currertRound; // the starting point is 1
        uint16 currertGame; // max 16777216
        uint lastCharge;    // cost of building a team in Gwei
        uint currentCharge; // fibonacci number
        uint dateNode;      // defint endTime
    }
    struct team {
        string name;
        address payable[] members;
        teamRule rule;
        uint8 countryRegion;
        uint8 beginningRound;
        uint8 endingRound;
        uint8 attackIndex;
        uint totalAmount;
        uint maxAttackAmount;   // max amount member
        uint[] subAmount;
    }
    struct teamSummary {
        string name;
        teamRule rule;
        uint8 countryRegion;
        uint8 beginningRound;
        uint8 endingRound;
        uint8 attackIndex;
        uint totalAmount;
        uint maxAttackAmount;
        uint membersLength;
        uint[] subAmount;
    }
    struct memberInfo {
        string message;
        uint8 attackIndex;
        join[] joins;
        uint balance;
    }
    struct join {
        uint8 teamIndex;
        uint amount;
    }
    constructor() public {
        config = gameConfig({developer:msg.sender, teamsCount:0, currertGame:0, currertRound:1, lastCharge:1000000000, currentCharge:1000000000, dateNode:now+99 days});
        
    }
    function newGame() private {
        // winner is free to next game
        (config.teamsCount, config.lastCharge, config.currentCharge, config.currertRound,     config.currertGame, teams.length)
        =(               0,        1000000000,           1000000000,                   1, config.currertGame + 1,            0);
    }
    function newTeam(string memory name, uint8 countryRegion, teamRule rule, uint8 attackIndex, string memory message) public payable {
        require(msg.value > config.currentCharge, "The amount is not enough to build up a team.");
        uint amount = msg.value - config.currentCharge;
        //stateCheck();
        uint8 teamIndex = uint8(teams.length++);
        config.teamsCount++;
        (teams[teamIndex].name, teams[teamIndex].countryRegion, teams[teamIndex].rule) = (name, countryRegion, rule);
        (teams[teamIndex].beginningRound, teams[teamIndex].endingRound, teams[teamIndex].totalAmount) = (config.currertRound, config.currertRound, amount);
        teams[teamIndex].members[teams[teamIndex].members.length++] = msg.sender;
        addr2member[msg.sender].joins[addr2member[msg.sender].joins.length++] = join({teamIndex:teamIndex, amount:amount});
        addr2member[config.developer].balance += config.currentCharge;  // team building cost transfer to developer account
        (config.currentCharge, config.lastCharge) = (config.currentCharge + config.lastCharge, config.currentCharge);   // calculate next fibonacci number
        attackTeam(attackIndex, message);
    }
    function joinTeam(uint8 teamIndex, uint8 attackIndex, string memory message) public payable {
        require(msg.value > 0, "Your amount is empty.");
        require(teams[teamIndex].endingRound == config.currertRound, "The team is not in currertRound.");
        //stateCheck();
        teams[teamIndex].totalAmount += msg.value;
        uint8 i = 0;
        for(; i < addr2member[msg.sender].joins.length; i++) {
            if(addr2member[msg.sender].joins[i].teamIndex == teamIndex) {   // has joined this team before
                if(teams[teamIndex].rule == teamRule.democratic) {
                    if(addr2member[msg.sender].attackIndex == attackIndex)
                        teams[teamIndex].subAmount[attackIndex] += msg.value;
                    else {
                        if(teams[teamIndex].subAmount.length > attackIndex == false)
                            teams[teamIndex].subAmount.length = attackIndex + 1;
                        teams[teamIndex].subAmount[addr2member[msg.sender].attackIndex] -= addr2member[msg.sender].joins[i].amount;
                        teams[teamIndex].subAmount[attackIndex] += addr2member[msg.sender].joins[i].amount + msg.value;
                    }
                }
                addr2member[msg.sender].joins[i].amount += msg.value;
                i = 255;
            }
        }
        if(i == 255) {                                                      // first time to join
            teams[teamIndex].members[teams[teamIndex].members.length++] = msg.sender;
            addr2member[msg.sender].joins[addr2member[msg.sender].joins.length++] = join({teamIndex:teamIndex, amount:msg.value});
            if(teams[teamIndex].rule == teamRule.democratic) {
                if(teams[teamIndex].subAmount.length > attackIndex == false)
                    teams[teamIndex].subAmount.length = attackIndex + 1;
                teams[teamIndex].subAmount[attackIndex] += msg.value;
            }
        }
        attackTeam(attackIndex, message);
    }
    function attackTeam(uint8 attackIndex, string memory message) public {
        for(uint8 i = 0; i < addr2member[msg.sender].joins.length; i++) {
            uint8 teamIndex = addr2member[msg.sender].joins[i].teamIndex;
            uint8 teamAttack = teams[teamIndex].attackIndex;
            uint memberAmount = addr2member[msg.sender].joins[i].amount;
            if(teams[teamIndex].members.length == 1) {  // from function new()
                if(teams[teamIndex].rule == teamRule.dictatorship)
                    teams[teamIndex].maxAttackAmount = memberAmount;
                else if(teams[teamIndex].rule == teamRule.democratic) {
                    (teams[teamIndex].maxAttackAmount, teams[teamIndex].subAmount.length) = (memberAmount, attackIndex + 1);
                    teams[teamIndex].subAmount[attackIndex] = memberAmount;
                }
                teams[teamIndex].attackIndex = attackIndex;
            }
            else if(teams[teamIndex].rule == teamRule.dictatorship) {
                if(memberAmount >= teams[teamIndex].maxAttackAmount) {
                    teams[teamIndex].maxAttackAmount = memberAmount;
                    if(teamAttack != attackIndex)
                        teams[teamIndex].attackIndex = attackIndex;
                }
            }                                               // decide on maximum amount
            else if(teams[teamIndex].rule == teamRule.democratic) {
                if(teams[teamIndex].subAmount.length > attackIndex == false)
                    teams[teamIndex].subAmount.length = attackIndex + 1;
                (teams[teamIndex].attackIndex, teams[teamIndex].maxAttackAmount) = subMax(teamIndex);
            }                                               // decide on subtotal everyone
            else if(teams[teamIndex].rule == teamRule.originator && teams[teamIndex].members[0] == msg.sender && teams[teamIndex].attackIndex != attackIndex)
                teams[teamIndex].attackIndex = attackIndex; // decide on originator
        }
        if(addr2member[msg.sender].attackIndex != attackIndex)
            addr2member[msg.sender].attackIndex = attackIndex;
        if(bytes(message).length > 0)
            addr2member[msg.sender].message = message;
    }
    function stateCheck() public {
        if(now >= config.dateNode + 1 days) {
            if(config.teamsCount >= 2) {  // goto next round
                uint8 i;
                uint8 eliminateIndex;   // eliminate Team's index number in teams arrary
                uint maxInjury;       // max injury
                uint denominator;     // total Gwei in this round
                uint[] memory injury = new uint[](teams.length);
                for(i = 0; i < teams.length; i++) {
                    if(teams[i].endingRound == config.currertRound) {
                        denominator += teams[i].totalAmount;
                        if(teams[teams[i].attackIndex].endingRound == config.currertRound) {
                            injury[teams[i].attackIndex] += teams[i].totalAmount;
                            if(injury[teams[i].attackIndex] > maxInjury)
                                (eliminateIndex, maxInjury) = (teams[i].attackIndex, injury[teams[i].attackIndex]);
                        }
                    }
                }
                denominator -= teams[eliminateIndex].totalAmount;
                uint numerator = teams[eliminateIndex].totalAmount * 32 / 33;
                addr2member[config.developer].balance += teams[eliminateIndex].totalAmount - numerator; // 3 percents developer fee
                for(i = 0; i < teams.length; i++) { // promote
                    if(teams[i].endingRound == config.currertRound) {
                        for(uint32 j = 0; j < teams[i].members.length; j++) {
                            for(uint8 k = 0; k < addr2member[teams[i].members[j]].joins.length; k++) {
                                if(addr2member[teams[i].members[j]].joins[k].teamIndex == i) {
                                    if(i != eliminateIndex)
                                        addr2member[teams[i].members[j]].balance += addr2member[teams[i].members[j]].joins[k].amount * numerator / denominator;
                                    if(k+1 < addr2member[teams[i].members[j]].joins.length)
                                        addr2member[teams[i].members[j]].joins[k] = addr2member[teams[i].members[j]].joins[addr2member[teams[i].members[j]].joins.length-1];
                                    addr2member[teams[i].members[j]].joins.length--;
                                    break;
                                }
                            }
                        }
                        if(i != eliminateIndex)
                            teams[i].endingRound++;
                    }
                }
                delete teams[eliminateIndex].members;
                config.currertRound++;
                config.teamsCount--;
            }
            else {                  // goto next game
                newGame();
            }
            config.dateNode += 1 days;
        }
    }
    function drawGwei(address payable target, uint amount) public payable {
        require(addr2member[msg.sender].balance >= amount , "Balance is not enough.");
        //stateCheck();
        addr2member[msg.sender].balance -= amount;
        target.transfer(amount);
    }
    function summary() public view returns(uint16, uint8, uint, uint, teamSummary[] memory) {
        teamSummary[] memory teamsSummary = new teamSummary[](teams.length);
        for(uint8 i = 0; i < teams.length; i++) {
            (teamsSummary[i].name, teamsSummary[i].countryRegion, teamsSummary[i].rule, teamsSummary[i].beginningRound, teamsSummary[i].endingRound)
            =(      teams[i].name,        teams[i].countryRegion,        teams[i].rule,        teams[i].beginningRound,        teams[i].endingRound);
            if(teams[i].endingRound == config.currertRound)
                (teamsSummary[i].attackIndex, teamsSummary[i].totalAmount, teamsSummary[i].maxAttackAmount, teamsSummary[i].subAmount, teamsSummary[i].membersLength)
                =(      teams[i].attackIndex,        teams[i].totalAmount,        teams[i].maxAttackAmount,        teams[i].subAmount,       teams[i].members.length);
        }
        return (config.currertGame, config.currertRound, config.currentCharge, config.dateNode, teamsSummary);
    }
    function subMax(uint8 teamIndex) private view returns(uint8, uint) {
        uint8 index;
        uint maxAmount;
        for(uint8 i = 0; i < teams[teamIndex].subAmount.length; i++) {
            if(teams[teamIndex].subAmount[i] >= maxAmount)
                (index, maxAmount) = (i, teams[teamIndex].subAmount[i]);
        }
        return (index, maxAmount);
    }
}
