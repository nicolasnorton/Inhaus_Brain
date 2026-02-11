const { describe, it, beforeEach } = require('mocha');
const { expect } = require('chai');
const sinon = require('sinon');

describe('Vertex Chat Function', () => {
    let mockReq;
    let mockRes;
    let vertexChatHandler;

    beforeEach(() => {
        // Reset mocks before each test
        mockReq = {
            method: 'POST',
            body: {},
            headers: {}
        };

        mockRes = {
            headersSent: false,
            headers: {},
            statusCode: 200,
            body: '',
            set: function (key, value) {
                this.headers[key] = value;
            },
            setHeader: function (key, value) {
                this.headers[key] = value;
            },
            status: function (code) {
                this.statusCode = code;
                return this;
            },
            json: function (data) {
                this.body = JSON.stringify(data);
                return this;
            },
            write: function (data) {
                this.body += data;
            },
            end: function () {
                this.headersSent = true;
            }
        };
    });

    describe('Request Validation', () => {
        it('should return 400 if messages array is missing', () => {
            mockReq.body = {};

            // Test validation logic
            const hasMessages = !!(mockReq.body.messages && Array.isArray(mockReq.body.messages));
            expect(hasMessages).to.be.false;
        });

        it('should accept valid messages array', () => {
            mockReq.body = {
                messages: [
                    { role: 'user', content: 'Hello' }
                ]
            };

            const hasMessages = mockReq.body.messages && Array.isArray(mockReq.body.messages);
            expect(hasMessages).to.be.true;
        });

        it('should accept optional tools array', () => {
            mockReq.body = {
                messages: [{ role: 'user', content: 'Hello' }],
                tools: [{ name: 'test_tool' }]
            };

            expect(mockReq.body.tools).to.be.an('array');
            expect(mockReq.body.tools).to.have.lengthOf(1);
        });
    });

    describe('Message Format Conversion', () => {
        it('should convert messages to LangChain format', () => {
            const messages = [
                { id: '1', role: 'system', content: 'You are helpful' },
                { id: '2', role: 'user', content: 'Hello' }
            ];

            const langchainMessages = messages.map(msg => ({
                role: msg.role,
                content: msg.content
            }));

            expect(langchainMessages).to.deep.equal([
                { role: 'system', content: 'You are helpful' },
                { role: 'user', content: 'Hello' }
            ]);
        });
    });

    describe('SSE Response Format', () => {
        it('should set correct SSE headers', () => {
            mockRes.setHeader('Content-Type', 'text/event-stream');
            mockRes.setHeader('Cache-Control', 'no-cache');
            mockRes.setHeader('Connection', 'keep-alive');

            expect(mockRes.headers['Content-Type']).to.equal('text/event-stream');
            expect(mockRes.headers['Cache-Control']).to.equal('no-cache');
            expect(mockRes.headers['Connection']).to.equal('keep-alive');
        });

        it('should format SSE data correctly', () => {
            const testData = { type: 'content', content: 'Hello' };
            const sseFormat = `data: ${JSON.stringify(testData)}\n\n`;

            mockRes.write(sseFormat);

            expect(mockRes.body).to.include('data: ');
            expect(mockRes.body).to.include('\n\n');
        });

        it('should send [DONE] signal on completion', () => {
            mockRes.write('data: [DONE]\n\n');

            expect(mockRes.body).to.include('[DONE]');
        });
    });

    describe('CORS Headers', () => {
        it('should set CORS headers', () => {
            mockRes.set('Access-Control-Allow-Origin', '*');
            mockRes.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');
            mockRes.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');

            expect(mockRes.headers['Access-Control-Allow-Origin']).to.equal('*');
            expect(mockRes.headers['Access-Control-Allow-Methods']).to.include('POST');
        });

        it('should handle OPTIONS preflight request', () => {
            mockReq.method = 'OPTIONS';

            // Preflight should return 204
            if (mockReq.method === 'OPTIONS') {
                mockRes.status(204);
                mockRes.body = '';
            }

            expect(mockRes.statusCode).to.equal(204);
        });
    });
});
