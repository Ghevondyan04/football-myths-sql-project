CREATE TABLE Team (
    TeamID INT IDENTITY(1,1) PRIMARY KEY,
    TeamName VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE Tournament (
    TournamentID INT IDENTITY(1,1) PRIMARY KEY,
    TournamentName VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE Location (
    LocationID INT IDENTITY(1,1) PRIMARY KEY,
    City VARCHAR(255) NOT NULL,
    Country VARCHAR(255) NOT NULL,
    CONSTRAINT UQ_City_Country UNIQUE (City, Country)
);


CREATE TABLE Fact_match (
    MatchID INT IDENTITY(1,1) PRIMARY KEY,
    MatchDate DATE NOT NULL, 
    HomeTeamID INT NOT NULL,
    AwayTeamID INT NOT NULL,
    HomeScore INT NOT NULL,
    AwayScore INT NOT NULL,
    TournamentID INT NOT NULL,
    LocationID INT NOT NULL,
    IsNeutral BIT NOT NULL,
    FOREIGN KEY (HomeTeamID) REFERENCES Team(TeamID), 
    FOREIGN KEY (AwayTeamID) REFERENCES Team(TeamID),
    FOREIGN KEY (TournamentID) REFERENCES Tournament(TournamentID),
    FOREIGN KEY (LocationID) REFERENCES Location(LocationID),
    CONSTRAINT UQ_Match UNIQUE (MatchDate, HomeTeamID, AwayTeamID) -- To prevent duplicate matches on the same date between the same teams
);

CREATE TABLE Fact_shootout (
    ShootoutID INT IDENTITY(1,1) PRIMARY KEY,
    MatchID INT NOT NULL,
    WinnerTeamID INT NOT NULL,
    FirstShooterTeamID INT NULL,
    FOREIGN KEY (MatchID) REFERENCES Fact_match(MatchID),
    FOREIGN KEY (WinnerTeamID) REFERENCES Team(TeamID),
    FOREIGN KEY (FirstShooterTeamID) REFERENCES Team(TeamID)
);

CREATE TABLE Fact_goalscorer (
    GoalID INT IDENTITY(1,1) PRIMARY KEY,
    MatchID INT NOT NULL,
    ScoringTeamID INT NOT NULL,
    ScorerName VARCHAR(255) NOT NULL,
    Minute INT NULL,
    IsOwnGoal BIT NOT NULL,
    IsPenalty BIT NOT NULL,
    FOREIGN KEY (MatchID) REFERENCES Fact_match(MatchID),
    FOREIGN KEY (ScoringTeamID) REFERENCES Team(TeamID)
);


CREATE INDEX IX_MatchDate ON Fact_match(MatchDate);
CREATE INDEX IX_HomeTeam ON Fact_match(HomeTeamID);
CREATE INDEX IX_AwayTeam ON Fact_match(AwayTeamID);
CREATE INDEX IX_Shootout_Match ON Fact_shootout(MatchID);
CREATE INDEX IX_Goalscorer_Match ON Fact_goalscorer(MatchID);

/* =========================================================
   Indexes for faster joins and analysis queries
   ========================================================= */

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_Fact_match_HomeTeamID'
      AND object_id = OBJECT_ID('dbo.Fact_match')
)
CREATE INDEX IX_Fact_match_HomeTeamID
ON dbo.Fact_match(HomeTeamID);


IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_Fact_match_AwayTeamID'
      AND object_id = OBJECT_ID('dbo.Fact_match')
)
CREATE INDEX IX_Fact_match_AwayTeamID
ON dbo.Fact_match(AwayTeamID);


IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_Fact_match_TournamentID'
      AND object_id = OBJECT_ID('dbo.Fact_match')
)
CREATE INDEX IX_Fact_match_TournamentID
ON dbo.Fact_match(TournamentID);


IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_Fact_match_LocationID'
      AND object_id = OBJECT_ID('dbo.Fact_match')
)
CREATE INDEX IX_Fact_match_LocationID
ON dbo.Fact_match(LocationID);


IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_Fact_shootout_MatchID'
      AND object_id = OBJECT_ID('dbo.Fact_shootout')
)
CREATE INDEX IX_Fact_shootout_MatchID
ON dbo.Fact_shootout(MatchID);


IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_Fact_goalscorer_MatchID'
      AND object_id = OBJECT_ID('dbo.Fact_goalscorer')
)
CREATE INDEX IX_Fact_goalscorer_MatchID
ON dbo.Fact_goalscorer(MatchID);


IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_Fact_goalscorer_ScoringTeamID'
      AND object_id = OBJECT_ID('dbo.Fact_goalscorer')
)
CREATE INDEX IX_Fact_goalscorer_ScoringTeamID
ON dbo.Fact_goalscorer(ScoringTeamID);

