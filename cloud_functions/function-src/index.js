// index.js - Node.js example function
exports.helloWorld = (req, res) => {
    const name = req.query.name || 'World';
    res.send(`Hello, ${name}!`);
  };
  