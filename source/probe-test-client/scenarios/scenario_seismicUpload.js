'use strict';

// Imports
const should = require('chai').Should();
const { expect } = require('chai');
const request = require("supertest");
const config = require(`${__dirname}/../config`);
const testUtils = require(`${__dirname}/../utils/testUtils`);
const telemetryUtils = require(`${__dirname}/../utils/telemetryUtils`);
const { assert } = require('console');

// Test Setup
let scenario = "scenario_seismicUpload";

const majorVersion = testUtils.between(1, 100000);
const minorVersion = testUtils.between(1, 100000);
let runId = `${majorVersion}.${minorVersion}`;
console.log(`run ID: ${runId}`);

let test = {
    runId: runId,
    scenario: scenario,
    service: "service",
    api: "api",
    expectedResponse: -1,
    failedTests: 0,
};

//must follow regex of [a-z][a-z\d\-]*[a-z\d]
let subprojectName = 'bvtsubproject1';
let subprojectCreateBody = {
    "admin": "nikarsky@microsoft.com",
    "storage_class": "REGIONAL",
    "storage_location": "US-CENTRAL1"
};
let gcsAccessToken = '';

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

    //This scenario implicitly tests partition and legal because the chain of calls begins
    //with getting the partition and a valid legal tag. Without either it won't work.
    describe('Scenario: Seismic Storage Testing', (done) => {

        if (config.test_flags.scenario_seismicUpload.enableScenario) {

            describe('Register Subproject', (done) => {
                //setup for upload
                it("Register Test Subproject.", done => {
                    test.service = testUtils.services.seismic;
                    test.api = test.service.api.createSubproject;
                    test.expectedResponse = test.api.expectedResponse;

                    test.service.host
                        .post(test.api.path + '/' + testUtils.partition + '/subproject/' + subprojectName)
                        .set('Authorization', token)
                        .set('Accept', 'application/json')
                        .set('data-partition-id', testUtils.partition)
                        .send(subprojectCreateBody)
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


            describe('Upload New to ACS', (done) => {

                //setup for upload
                it("Utility Get GCS", done => {
                    test.service = testUtils.services.seismic;
                    test.api = test.service.api.getGCS;
                    test.expectedResponse = test.api.expectedResponse;

                    test.service.host
                        .get(test.api.path + '?sdpath=sd://' + testUtils.partition +
                            '/' + subprojectName + "&readonly=false")
                        .set('Authorization', token)
                        .set('Accept', 'application/json')
                        .set('data-partition-id', testUtils.partition)
                        .then(res => {
                            test.expectedResponse.should.be.an('array').that.includes(res.statusCode);
                            gcsAccessToken = res.body.access_token;
                            telemetryUtils.passApiRequest(test);
                            done();
                        })
                        .catch(err => {
                            telemetryUtils.failApiRequest(test, err);
                            done(err);
                        });
                });
                //upload
                it("Test Storage Seismic Upload", done => {
                    test.service = testUtils.services.seismic;
                    test.api = test.service.api.getGCS;
                    test.expectedResponse = test.api.expectedResponse;
                    var uploadUrl = gcsAccessToken.replace('?', '//o?');
                    request(uploadUrl)
                        .put('')
                        .set('Content-type', 'text/plain')
                        .set('x-ms-blob-type', 'BlockBlob')
                        .set('data-partition-id', testUtils.partition)
                        .send("test")
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
            });

            describe('Delete Subproject', (done) => {
                //cleanup
                it("Delete Test Subproject.", done => {
                    test.service = testUtils.services.seismic;
                    test.api = test.service.api.createSubproject;
                    test.expectedResponse = test.api.expectedResponse;

                    test.service.host
                        .delete(test.api.path + '/' + testUtils.partition + '/subproject/' + subprojectName)
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

        afterEach(function () {
            if (this.currentTest.state === 'failed') {
                test.failedTests += 1;
            }
        });

        after(done => {
            telemetryUtils.scenarioRequest(runId, testUtils.services.seismic, scenario, test.failedTests);
            done();
        });
    });
});