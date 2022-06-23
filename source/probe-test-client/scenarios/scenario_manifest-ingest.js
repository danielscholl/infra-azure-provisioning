'use strict';

// Imports
const should = require('chai').Should();
const {
    expect
} = require('chai');
const request = require("supertest");
const config = require(`${__dirname}/../config`);
const testUtils = require(`${__dirname}/../utils/testUtils`);
const telemetryUtils = require(`${__dirname}/../utils/telemetryUtils`);
const {
    assert
} = require('console');
var isEqual = require('lodash.isequal');

// Test Setup
let scenario = "scenario_manifest-ingest";

const majorVersion = testUtils.between(1, 100000);
const minorVersion = testUtils.between(1, 100000);
let runId = `${majorVersion}.${minorVersion}`;
console.log(`run ID: ${runId}`);
let referenceId = '';

let test = {
    runId: runId,
    scenario: scenario,
    service: "service",
    api: "api",
    expectedResponse: -1,
    failedTests: 0,
};

// Test Data Setup
let testApiName = testUtils.services.search.api.search.name;
let source = "wks";
let kind = `osdu:${source}:Manifest:1.0.0`;
let workflow_name = "Osdu_ingest";
let tag = `${testUtils.partition}-public-usa-check-1`;
let authority = `osdu`;

let legalTag = {
    "name": `${tag}`,
    "description": "This tag is used by Data Upload Scripts",
    "properties": {
        "countryOfOrigin": [
            "US"
        ],
        "contractId": "A1234",
        "expirationDate": "3021-12-31",
        "originator": "MyCompany",
        "dataType": "Transferred Data",
        "securityClassification": "Public",
        "personalData": "No Personal Data",
        "exportClassification": "EAR99"
    }
}

let data = '';


// Test Scenario
describe(scenario, (done) => {
    let token;

    before(done => {
        // Get a new OAuth Token
        testUtils.oAuth.post('/token')
            .set('Content-Type', 'application/x-www-form-urlencoded')
            .send(config.auth_params)
            .then(res => {
                token = 'Bearer ' + res.body.access_token;
                done();
            })
            .catch(err => {
                done(err)
            });
    });

    describe('Scenario: Manifest Ingest', (done) => {

        if (config.test_flags.scenario_manifest_ingest.enableScenario) {

            describe('Get Entitlements', (done) => {

                it("Get All groups.", done => {
                    test.service = testUtils.services.entitlement;
                    test.api = test.service.api.getGroups;
                    test.expectedResponse = test.api.expectedResponse;

                    test.service.host
                        .get(test.api.path)
                        .set('Authorization', token)
                        .set('Accept', 'application/json')
                        .set('data-partition-id', testUtils.partition)
                        .expect(test.expectedResponse)
                        .then(() => {
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err);
                        });
                });
            });

            describe('Create Necessary Legal Tag', (done) => {

                it("Create Legal Tag", done => {
                    test.service = testUtils.services.legal;
                    test.api = test.service.api.createLegalTags;
                    test.expectedResponse = test.api.expectedResponse;

                    test.service.host
                        .post(test.api.path)
                        .set('Authorization', token)
                        .set('Content-Type', 'application/json')
                        .set('data-partition-id', testUtils.partition)
                        .send(legalTag)
                        .then(res => {
                            test.expectedResponse.should.be.an('array').that.includes(res.statusCode);
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err)
                        });
                });

                it("Get Created Legal Tag", done => {
                    test.service = testUtils.services.legal;
                    test.api = test.service.api.getLegalTag;
                    test.expectedResponse = test.api.expectedResponse;

                    test.service.host
                        .get(test.api.path + legalTag.name)
                        .set('Authorization', token)
                        .set('Accept', 'application/json')
                        .set('data-partition-id', testUtils.partition)
                        .expect(test.expectedResponse)
                        .then(res => {
                            data = res.body;
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err);
                        });
                });

                it('Validate: Get Created Legal Tag', () => {
                    test.service = testUtils.services.legal;
                    test.api.name = 'validate_' + test.service.api.getLegalTag.name;
                    test.expectedResponse = "Valid Match";

                    if (isEqual(data, legalTag)) {
                        telemetryUtils.passApiRequest(test);
                        expect(true).to.be.true;
                    } else {
                        telemetryUtils.failApiRequest(test, "Invalid");
                        console.log(`actual:${JSON.stringify(data)}`);
                        expect(false).to.be.true;
                    }
                });
            });

            describe('Check Necessary Schema', (done) => {

                it("Get WKS Manifest Schema By ID", done => {
                    test.service = testUtils.services.schema;
                    test.api = test.service.api.getSchemaById;
                    test.expectedResponse = test.api.expectedResponse;

                    test.service.host
                        .get(test.api.path + kind)
                        .set('Authorization', token)
                        .set('Accept', 'application/json')
                        .set('data-partition-id', testUtils.partition)
                        .expect(test.expectedResponse)
                        .then(() => {
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err);
                        });
                });
            });

            describe('Create Workflow', (done) => {

                it("Create Workflow", done => {
                    test.service = testUtils.services.workflow;
                    test.api = test.service.api.createWorkflow;
                    test.expectedResponse = test.api.expectedResponse;

                    let workflowPayload = {
                        "workflowName": `${workflow_name}`,
                        "description": "Manifest Ingestion DAGs workflow",
                        "registrationInstructions": {
                            "concurrentWorkflowRun": 5,
                            "concurrentTaskRun": 5,
                            "workflowDetailContent": "",
                            "active": true
                        }
                    };

                    test.service.host
                        .post(test.api.path)
                        .set('Authorization', token)
                        .set('Content-Type', 'application/json')
                        .set('data-partition-id', testUtils.partition)
                        .send(workflowPayload)
                        .then(res => {
                            test.expectedResponse.should.be.an('array').that.includes(res.statusCode);
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err);
                        });
                });

                it("Get Workflow By Name", done => {

                    test.service = testUtils.services.workflow;
                    test.api = test.service.api.getWorkflowByName;
                    test.expectedResponse = test.api.expectedResponse;

                    test.service.host
                        .get(test.api.path + workflow_name)
                        .set('Authorization', token)
                        .set('Content-Type', 'application/json')
                        .set('data-partition-id', testUtils.partition)
                        .expect(test.expectedResponse)
                        .then(res => {
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err);
                        });
                });
            });

            describe('Manifest Ingest #TC-1: Reference data processing parameter', (done) => {

                let payload = require(`${__dirname}/../testData/sample_manifest_ingest_tc1.json`);

                payload = JSON.parse(JSON.stringify(payload).replace(/##PARTITION##/g, `${testUtils.partition}`));
                payload = JSON.parse(JSON.stringify(payload).replace(/##SOURCE##/g, `${source}`));
                payload = JSON.parse(JSON.stringify(payload).replace(/##KIND##/g, `${kind}`));
                payload = JSON.parse(JSON.stringify(payload).replace(/##TAG##/g, `${tag}`));
                payload = JSON.parse(JSON.stringify(payload).replace(/##AUTHORITY##/g, `${authority}`));

                it("Trigger Workflow Run", done => {
                    test.service = testUtils.services.workflow;
                    test.api = test.service.api.runWorkflow;
                    test.expectedResponse = test.api.expectedResponse;

                    test.service.host
                        .post(test.api.path.prefix + workflow_name + test.api.path.suffix)
                        .set('Authorization', token)
                        .set('Content-Type', 'application/json')
                        .set('data-partition-id', testUtils.partition)
                        .send(payload)
                        .then(res => {
                            referenceId = res.body.runId;
                            test.expectedResponse.should.be.an('array').that.includes(res.statusCode);
                            should.exist(referenceId);
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err);
                        });
                });
            });

            describe('Manifest Ingest #TC-1: GET Workflow Run Status', (done) => {

                before((done) => {
                    setTimeout(done, 5000)
                });

                it("Get Workflow Reference Data Run", done => {
                    test.service = testUtils.services.workflow;
                    test.api = test.service.api.getWorkflowPreDefinedId;
                    test.expectedResponse = test.api.expectedResponse;

                    test.service.host
                        .get(test.api.path.prefix + workflow_name + test.api.path.suffix + referenceId)
                        .set('Authorization', token)
                        .set('Content-Type', 'application/json')
                        .set('data-partition-id', testUtils.partition)
                        .expect(test.expectedResponse)
                        .then(res => {
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err);
                        });
                });
            });


            describe('Manifest Ingest #TC-1: Search & cleanup for Reference Data', (done) => {

                let recordId = '';

                before((done) => {

                    console.log("Waiting for Dag Run to be completed...");
                    setTimeout(done, 120000)
                });

                it("Search: Record", done => {
                    test.service = testUtils.services.search;
                    test.api = test.service.api.search;
                    test.api.name = `${testApiName}_manifestIngest_record-tc5`;
                    test.expectedResponse = test.api.expectedResponse;
                    let recordIdValue = `${testUtils.partition}:reference-data--ProcessingParameterType:KirchhoffDepthMigration-12345`
                    let searchQuery = {
                        "kind": `osdu:${source}:reference-data--ProcessingParameterType:1.0.0`,
                        "query": `id:"${recordIdValue}"`,
                        "offset": 0,
                        "limit": 1
                    };

                    test.service.host
                        .post(test.api.path)
                        .set('Authorization', token)
                        .set('Content-Type', 'application/json')
                        .set('data-partition-id', testUtils.partition)
                        .send(searchQuery)
                        .then(res => {
                            test.expectedResponse.should.be.an('array').that.includes(res.statusCode);
                            console.log(`Total Record Count: ${res.body.totalCount}`)
                            recordId = res.body.results[0].id
                            should.exist(recordId);
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err)
                        });
                });

                it('Validate: Record', done => {
                    test.service = testUtils.services.storage;
                    test.api = test.service.api.getRecord;
                    test.expectedResponse = test.api.expectedResponse;

                    test.service.host
                        .get(test.api.path + recordId)
                        .set('Authorization', token)
                        .set('Accept', 'application/json')
                        .set('data-partition-id', testUtils.partition)
                        .expect(test.expectedResponse)
                        .then(() => {
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err);
                        });
                });

                it('Record: Delete', done => {
                    test.service = testUtils.services.storage;
                    test.api = test.service.api.deleteRecord;
                    test.expectedResponse = test.api.expectedResponse;

                    test.service.host
                        .delete(test.api.path + recordId)
                        .set('Authorization', token)
                        .set('data-partition-id', testUtils.partition)
                        .expect(test.expectedResponse)
                        .then(() => {
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err);
                        });
                });
            });




            describe('Manifest Ingest #TC-2: Reference data multiple resources', (done) => {

                let payload = require(`${__dirname}/../testData/sample_manifest_ingest_tc2.json`);

                payload = JSON.parse(JSON.stringify(payload).replace(/##PARTITION##/g, `${testUtils.partition}`));
                payload = JSON.parse(JSON.stringify(payload).replace(/##SOURCE##/g, `${source}`));
                payload = JSON.parse(JSON.stringify(payload).replace(/##KIND##/g, `${kind}`));
                payload = JSON.parse(JSON.stringify(payload).replace(/##TAG##/g, `${tag}`));
                payload = JSON.parse(JSON.stringify(payload).replace(/##AUTHORITY##/g, `${authority}`));

                let referenceId = '';

                it("Trigger Workflow Run", done => {
                    test.service = testUtils.services.workflow;
                    test.api = test.service.api.runWorkflow;
                    test.expectedResponse = test.api.expectedResponse;

                    test.service.host
                        .post(test.api.path.prefix + workflow_name + test.api.path.suffix)
                        .set('Authorization', token)
                        .set('Content-Type', 'application/json')
                        .set('data-partition-id', testUtils.partition)
                        .send(payload)
                        .then(res => {
                            referenceId = res.body.runId;
                            test.expectedResponse.should.be.an('array').that.includes(res.statusCode);
                            should.exist(referenceId);
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err);
                        });
                });
            });

            describe('Manifest Ingest #TC-2: GET Workflow Run Status', (done) => {

                before((done) => {
                    setTimeout(done, 5000)
                });

                it("Get Workflow Reference Data Run", done => {
                    test.service = testUtils.services.workflow;
                    test.api = test.service.api.getWorkflowPreDefinedId;
                    test.expectedResponse = test.api.expectedResponse;

                    test.service.host
                        .get(test.api.path.prefix + workflow_name + test.api.path.suffix + referenceId)
                        .set('Authorization', token)
                        .set('Content-Type', 'application/json')
                        .set('data-partition-id', testUtils.partition)
                        .expect(test.expectedResponse)
                        .then(res => {
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err);
                        });
                });
            });


            describe('Manifest Ingest #TC-2: Search & cleanup for Reference Data multiple resources', (done) => {

                let recordId = '';
                before((done) => {

                    console.log("Waiting for Dag Run to be completed...");
                    setTimeout(done, 120000)
                });

                it("Search: Record", done => {
                    test.service = testUtils.services.search;
                    test.api = test.service.api.search;
                    test.api.name = `${testApiName}_manifestIngest_record-tc5`;
                    test.expectedResponse = test.api.expectedResponse;
                    let recordIdValue = `${testUtils.partition}:reference-data--ProcessingParameterType:AngleMute-12345`
                    let searchQuery = {
                        "kind": `osdu:${source}:reference-data--ProcessingParameterType:1.0.0`,
                        "query": `id:"${recordIdValue}"`,
                        "offset": 0,
                        "limit": 1
                    };

                    test.service.host
                        .post(test.api.path)
                        .set('Authorization', token)
                        .set('Content-Type', 'application/json')
                        .set('data-partition-id', testUtils.partition)
                        .send(searchQuery)
                        .then(res => {
                            test.expectedResponse.should.be.an('array').that.includes(res.statusCode);
                            console.log(`Total Record Count: ${res.body.totalCount}`)
                            recordId = res.body.results[0].id
                            should.exist(recordId);
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err)
                        });
                });

                it('Validate: Record', done => {
                    test.service = testUtils.services.storage;
                    test.api = test.service.api.getRecord;
                    test.expectedResponse = test.api.expectedResponse;

                    test.service.host
                        .get(test.api.path + recordId)
                        .set('Authorization', token)
                        .set('Accept', 'application/json')
                        .set('data-partition-id', testUtils.partition)
                        .expect(test.expectedResponse)
                        .then(() => {
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err);
                        });
                });

                it('Record: Delete', done => {
                    test.service = testUtils.services.storage;
                    test.api = test.service.api.deleteRecord;
                    test.expectedResponse = test.api.expectedResponse;

                    test.service.host
                        .delete(test.api.path + recordId)
                        .set('Authorization', token)
                        .set('data-partition-id', testUtils.partition)
                        .expect(test.expectedResponse)
                        .then(() => {
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err);
                        });
                });
            });


            describe('Manifest Ingest #TC-3: Master data ingestion (Well)', (done) => {

                let payload = require(`${__dirname}/../testData/sample_manifest_ingest_tc3.json`);
                payload = JSON.parse(JSON.stringify(payload).replace(/##PARTITION##/g, `${testUtils.partition}`));
                payload = JSON.parse(JSON.stringify(payload).replace(/##SOURCE##/g, `${source}`));
                payload = JSON.parse(JSON.stringify(payload).replace(/##KIND##/g, `${kind}`));
                payload = JSON.parse(JSON.stringify(payload).replace(/##TAG##/g, `${tag}`));
                payload = JSON.parse(JSON.stringify(payload).replace(/##AUTHORITY##/g, `${authority}`));

                let referenceId = '';

                it("Trigger Workflow Run", done => {
                    test.service = testUtils.services.workflow;
                    test.api = test.service.api.runWorkflow;
                    test.expectedResponse = test.api.expectedResponse;

                    test.service.host
                        .post(test.api.path.prefix + workflow_name + test.api.path.suffix)
                        .set('Authorization', token)
                        .set('Content-Type', 'application/json')
                        .set('data-partition-id', testUtils.partition)
                        .send(payload)
                        .then(res => {
                            referenceId = res.body.runId;
                            test.expectedResponse.should.be.an('array').that.includes(res.statusCode);
                            should.exist(referenceId);
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err);
                        });
                });
            });

            describe('Manifest Ingest #TC-3: GET Workflow Run Status', (done) => {

                before((done) => {
                    setTimeout(done, 5000)
                });

                it("Get Workflow Reference Data Run", done => {
                    test.service = testUtils.services.workflow;
                    test.api = test.service.api.getWorkflowPreDefinedId;
                    test.expectedResponse = test.api.expectedResponse;

                    test.service.host
                        .get(test.api.path.prefix + workflow_name + test.api.path.suffix + referenceId)
                        .set('Authorization', token)
                        .set('Content-Type', 'application/json')
                        .set('data-partition-id', testUtils.partition)
                        .expect(test.expectedResponse)
                        .then(res => {
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err);
                        });
                });
            });

            describe('Manifest Ingest #TC-3: Search & cleanup for Master data ingestion (Well)', (done) => {

                let recordId = '';
                before((done) => {

                    console.log("Waiting for Dag Run to be completed...");
                    setTimeout(done, 120000)
                });

                it("Search: Record", done => {
                    test.service = testUtils.services.search;
                    test.api = test.service.api.search;
                    test.api.name = `${testApiName}_manifestIngest_record-tc5`;
                    test.expectedResponse = test.api.expectedResponse;
                    let recordIdValue = `${testUtils.partition}:master-data--Well:1111`
                    let searchQuery = {
                        "kind": `osdu:${source}:master-data--Well:1.0.0`,
                        "query": `id:"${recordIdValue}"`,
                        "offset": 0,
                        "limit": 1
                    };

                    test.service.host
                        .post(test.api.path)
                        .set('Authorization', token)
                        .set('Content-Type', 'application/json')
                        .set('data-partition-id', testUtils.partition)
                        .send(searchQuery)
                        .then(res => {
                            test.expectedResponse.should.be.an('array').that.includes(res.statusCode);
                            console.log(`Total Record Count: ${res.body.totalCount}`)
                            recordId = res.body.results[0].id
                            should.exist(recordId);
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err)
                        });
                });

                it('Validate: Record', done => {
                    test.service = testUtils.services.storage;
                    test.api = test.service.api.getRecord;
                    test.expectedResponse = test.api.expectedResponse;

                    test.service.host
                        .get(test.api.path + recordId)
                        .set('Authorization', token)
                        .set('Accept', 'application/json')
                        .set('data-partition-id', testUtils.partition)
                        .expect(test.expectedResponse)
                        .then(() => {
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err);
                        });
                });

                it('Record: Delete', done => {
                    test.service = testUtils.services.storage;
                    test.api = test.service.api.deleteRecord;
                    test.expectedResponse = test.api.expectedResponse;

                    test.service.host
                        .delete(test.api.path + recordId)
                        .set('Authorization', token)
                        .set('data-partition-id', testUtils.partition)
                        .expect(test.expectedResponse)
                        .then(() => {
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err);
                        });
                });
            });

            describe('Manifest Ingest #TC-4: WP ingestion', (done) => {

                let payload = require(`${__dirname}/../testData/sample_manifest_ingest_tc4.json`);
                payload = JSON.parse(JSON.stringify(payload).replace(/##PARTITION##/g, `${testUtils.partition}`));
                payload = JSON.parse(JSON.stringify(payload).replace(/##SOURCE##/g, `${source}`));
                payload = JSON.parse(JSON.stringify(payload).replace(/##KIND##/g, `${kind}`));
                payload = JSON.parse(JSON.stringify(payload).replace(/##TAG##/g, `${tag}`));
                payload = JSON.parse(JSON.stringify(payload).replace(/##AUTHORITY##/g, `${authority}`));

                let referenceId = '';

                it("Trigger Workflow Run", done => {
                    test.service = testUtils.services.workflow;
                    test.api = test.service.api.runWorkflow;
                    test.expectedResponse = test.api.expectedResponse;

                    test.service.host
                        .post(test.api.path.prefix + workflow_name + test.api.path.suffix)
                        .set('Authorization', token)
                        .set('Content-Type', 'application/json')
                        .set('data-partition-id', testUtils.partition)
                        .send(payload)
                        .then(res => {
                            referenceId = res.body.runId;
                            test.expectedResponse.should.be.an('array').that.includes(res.statusCode);
                            should.exist(referenceId);
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err);
                        });
                });

            });

            describe('Manifest Ingest #TC-4: GET Workflow Run Status', (done) => {

                before((done) => {
                    setTimeout(done, 5000)
                });

                it("Get Workflow Reference Data Run", done => {
                    test.service = testUtils.services.workflow;
                    test.api = test.service.api.getWorkflowPreDefinedId;
                    test.expectedResponse = test.api.expectedResponse;

                    test.service.host
                        .get(test.api.path.prefix + workflow_name + test.api.path.suffix + referenceId)
                        .set('Authorization', token)
                        .set('Content-Type', 'application/json')
                        .set('data-partition-id', testUtils.partition)
                        .expect(test.expectedResponse)
                        .then(res => {
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err);
                        });
                });
            });


            describe('Manifest Ingest #TC-4: Search & cleanup for WP ingestion', (done) => {

                let recordId = '';
                before((done) => {
                    console.log("Waiting for Dag Run to be completed...");
                    setTimeout(done, 120000)
                });

                it("Search: Record", done => {
                    test.service = testUtils.services.search;
                    test.api = test.service.api.search;
                    test.api.name = `${testApiName}_manifestIngest_record-tc5`;
                    test.expectedResponse = test.api.expectedResponse;
                    let recordIdValue = `${testUtils.partition}:work-product--WorkProduct:feb2`
                    let searchQuery = {
                        "kind": `osdu:${source}:work-product--WorkProduct:1.0.0`,
                        "query": `id:"${recordIdValue}"`,
                        "offset": 0,
                        "limit": 1
                    };

                    test.service.host
                        .post(test.api.path)
                        .set('Authorization', token)
                        .set('Content-Type', 'application/json')
                        .set('data-partition-id', testUtils.partition)
                        .send(searchQuery)
                        .then(res => {
                            test.expectedResponse.should.be.an('array').that.includes(res.statusCode);
                            console.log(`Total Record Count: ${res.body.totalCount}`)
                            recordId = res.body.results[0].id
                            should.exist(recordId);
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err)
                        });
                });

                it('Validate: Record', done => {
                    test.service = testUtils.services.storage;
                    test.api = test.service.api.getRecord;
                    test.expectedResponse = test.api.expectedResponse;

                    test.service.host
                        .get(test.api.path + recordId)
                        .set('Authorization', token)
                        .set('Accept', 'application/json')
                        .set('data-partition-id', testUtils.partition)
                        .expect(test.expectedResponse)
                        .then(() => {
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err);
                        });
                });

                it('Record: Delete', done => {
                    test.service = testUtils.services.storage;
                    test.api = test.service.api.deleteRecord;
                    test.expectedResponse = test.api.expectedResponse;

                    test.service.host
                        .delete(test.api.path + recordId)
                        .set('Authorization', token)
                        .set('data-partition-id', testUtils.partition)
                        .expect(test.expectedResponse)
                        .then(() => {
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err);
                        });
                });
            });



            describe('Probe Cleanup', (done) => {

                it('LegalTag: Delete', done => {
                    test.service = testUtils.services.legal;
                    test.api = test.service.api.deleteLegalTags;
                    test.expectedResponse = test.api.expectedResponse;

                    test.service.host
                        .delete(test.api.path + legalTag.name)
                        .set('Authorization', token)
                        .set('Accept', 'application/json')
                        .set('data-partition-id', testUtils.partition)
                        .expect(test.expectedResponse)
                        .then(() => {
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err);
                        });
                });
            });
        }

        afterEach(function() {
            if (this.currentTest.state === 'failed') {
                test.failedTests += 1;
            }
        });

        after(done => {
            telemetryUtils.scenarioRequest(runId, testUtils.services.workflow, scenario, test.failedTests);
            done();
        });
    });
});
