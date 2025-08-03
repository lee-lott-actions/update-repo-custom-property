const express = require('express');
const app = express();
app.use(express.json());

app.patch('/repos/:owner/:repo_name/properties/values', (req, res) => {
  console.log('Mock intercepted: PATCH /repos/' + req.params.owner + '/' + req.params.repo_name + '/properties/values');
  console.log('Request body:', JSON.stringify(req.body));

  // Validate the request body
  if (
    req.body.properties &&
    Array.isArray(req.body.properties) &&
    req.body.properties.length > 0 &&
    req.body.properties[0].property_name &&
    req.body.properties[0].value
  ) {
    res.status(204).send(); // GitHub API returns 204 No Content for successful property updates
  } else {
    res.status(400).json({ message: 'Invalid request: properties array with property_name and value is required' });
  }
});

app.listen(3000, () => {
  console.log('Mock server listening on http://127.0.0.1:3000...');
});
