-- Script per creare la tabella Doc_07ZR_perPdf e popolarla con i numeri documento

-- Elimina la tabella se esiste già
DROP TABLE IF EXISTS Doc_07ZR_perPdf;

-- Crea la tabella
CREATE TABLE Doc_07ZR_perPdf (
    ID AUTOINCREMENT PRIMARY KEY,
    NumeroDocumento TEXT(50) NOT NULL,
    Processato YESNO DEFAULT 0,
    DataInserimento DATETIME DEFAULT Now(),
    Note TEXT(255)
);

-- Inserisci tutti i numeri documento
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DG25507507');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DG26577400');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN05597907');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN14587308');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN15577209');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN20462595');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN22462494');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN26472094');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN29472096');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN30442690');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN37577209');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN43422199');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN44567706');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN48507706');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN50567102');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN56507007');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN57462194');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN58587707');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN59462094');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN59462195');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN60567109');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN63587706');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN65547804');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN66442894');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN70507009');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN72402195');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN72412797');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN73402292');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN75452396');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN76507006');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN78452892');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN80462198');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN80472490');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN80492798');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN84422996');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN94432594');
INSERT INTO Doc_07ZR_perPdf (NumeroDocumento) VALUES ('DN96442698');

-- Verifica che i dati siano stati inseriti correttamente
SELECT COUNT(*) AS TotaleDocumenti FROM Doc_07ZR_perPdf; 