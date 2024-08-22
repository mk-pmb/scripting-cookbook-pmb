
<!--#echo json="package.json" key="name" underline="=" -->
scripting-cookbook-pmb
======================
<!--/#echo -->

<!--#echo json="package.json" key="description" -->
A collection of code snippets for which I couln&#39;t find a better home.
<!--/#echo -->


Motivation
----------

On 2024-08-21 I wanted to share a little sed snippet that would be useful
as part of other sed scripts. However, to my knowledge, sed doesn't have a
package manager suitable for micro-packages, so the only realistic efficient
way of bundling this is probably to copy and paste it.
Which is horrible for maintainability and update management.

To mitigate this horror at least a little bit, my idea was to assign a UUID
and carry that around. That would help with discoverability.

But how do you know which version is the latest/best?
Where can you find documentation?
Where do you report issues with it?

That snippet should have some centralized homepage.
But giving it its own repo would be overkill.
I should start some kind of snippet collection.

(Update 2024-08-22: After adding some tests for that snippet and a proper
CI infrastructure for this repo, I discovered that the snippet was buggy,
and also overly complicated. The new version is too trivial to upload.)





<!--#toc stop="scan" -->



Known issues
------------

* Needs more/better tests and docs.




&nbsp;


License
-------
<!--#echo json="package.json" key=".license" -->
WTFPL
<!--/#echo -->
